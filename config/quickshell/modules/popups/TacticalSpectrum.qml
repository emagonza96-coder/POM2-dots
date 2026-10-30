import QtQuick
import "../.."

Item {
    id: spectrumRoot
    width: parent.width
    height: 62
    clip: true

    // Niveles de audio recibidos de CAVA (16 bandas, rango 0 - 8)
    property var values: [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
    property bool active: false

    readonly property int barsCount: 16
    readonly property int maxLevel: 8

    // Banco de símbolos tácticos dinámicos (!@#$%*()_+ y especiales)
    readonly property var symbolBank: ["!", "@", "#", "$", "%", "*", "(", ")", "+", "_", "~", "^"]

    // Tick de animación para mutación continua de símbolos con el ritmo
    property int animTick: 0

    // Retícula centrada sin recuadros ni texto de cabecera
    Row {
        id: barsRow
        anchors.centerIn: parent
        spacing: 4

        readonly property real colW: Math.floor((parent.width - (spectrumRoot.barsCount - 1) * 4) / spectrumRoot.barsCount)

        Repeater {
            id: spectrumRepeater
            model: spectrumRoot.barsCount

            Item {
                id: colItem
                property int colIndex: index
                width: barsRow.colW
                height: 56
                clip: true

                readonly property int rawVal: (spectrumRoot.values && spectrumRoot.values.length > index)
                    ? Math.min(spectrumRoot.maxLevel, Math.max(0, spectrumRoot.values[index]))
                    : 0

                property real smoothVal: 0
                property real peakVal: 0
                // Desfase individual por columna para que cada barra tenga símbolos distintos
                property int colShift: (index * 3) % spectrumRoot.symbolBank.length

                onRawValChanged: {
                    if (rawVal >= smoothVal) {
                        smoothVal = rawVal
                        // Al recibir un golpe de ritmo, la columna muta su símbolo
                        colShift = (colShift + 1) % spectrumRoot.symbolBank.length
                    }
                    if (rawVal >= peakVal) {
                        peakVal = rawVal
                    }
                }

                Column {
                    anchors.centerIn: parent
                    spacing: 0

                    // 8 niveles verticales de altura fija estricta (7px cada uno = 56px total)
                    Repeater {
                        model: spectrumRoot.maxLevel

                        Item {
                            readonly property int level: spectrumRoot.maxLevel - index
                            readonly property int currentInt: Math.round(colItem.smoothVal)
                            readonly property int peakInt: Math.round(colItem.peakVal)

                            readonly property bool isBody: spectrumRoot.active && (currentInt >= level)
                            readonly property bool isCrest: spectrumRoot.active && (currentInt === level) && (level > 1)
                            readonly property bool isPeak: spectrumRoot.active && (peakInt === level) && (peakInt > currentInt) && (level > 1)

                            width: colItem.width
                            height: 7
                            clip: true

                            Text {
                                anchors.centerIn: parent
                                text: {
                                    if (isPeak) {
                                        return (level >= 8) ? "!" : ((level >= 6) ? "@" : "^")
                                    }
                                    if (isCrest) {
                                        return (level >= 8) ? "!" : ((level >= 6) ? "@" : "^")
                                    }
                                    if (isBody) {
                                        // Cada barra y nivel rota dinámicamente con colShift y animTick
                                        let symIdx = (colItem.colShift + level + spectrumRoot.animTick) % spectrumRoot.symbolBank.length
                                        return spectrumRoot.symbolBank[symIdx]
                                    }
                                    if (level === 1) {
                                        // La línea base de abajo varía entre columnas y no es siempre igual
                                        let baseIdx = (colItem.colIndex + spectrumRoot.animTick) % 4
                                        if (baseIdx === 0) return "_"
                                        if (baseIdx === 1) return "="
                                        if (baseIdx === 2) return "~"
                                        return "-"
                                    }
                                    return ""
                                }

                                font.family: Theme.font
                                font.pixelSize: 9
                                font.bold: isPeak || isCrest || (level >= 6)

                                color: {
                                    if (isPeak) {
                                        return level >= 8 ? Theme.red : (level >= 6 ? Theme.amber : Theme.accent)
                                    }
                                    if (isBody) {
                                        if (level >= 8) return Theme.red
                                        if (level >= 6) return Theme.amber
                                        return Theme.accent
                                    }
                                    // Línea base en reposo
                                    return "#1c3220"
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // Timer de balística física y rotación rítmica de símbolos
    Timer {
        id: decayTimer
        interval: 35
        running: spectrumRoot.active
        repeat: true
        onTriggered: {
            for (let i = 0; i < spectrumRepeater.count; i++) {
                let item = spectrumRepeater.itemAt(i)
                if (item) {
                    if (item.smoothVal > item.rawVal) {
                        item.smoothVal = Math.max(item.rawVal, item.smoothVal - 0.4)
                    }
                    if (item.peakVal > item.rawVal) {
                        item.peakVal = Math.max(item.rawVal, item.peakVal - 0.15)
                    }
                }
            }
        }
    }

    // Timer rítmico que hace mutar los símbolos continuamente mientras la música suena
    Timer {
        id: morphTimer
        interval: 120
        running: spectrumRoot.active
        repeat: true
        onTriggered: {
            spectrumRoot.animTick = (spectrumRoot.animTick + 1) % 60
        }
    }
}
