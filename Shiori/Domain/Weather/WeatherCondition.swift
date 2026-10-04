nonisolated enum WeatherCondition: Int, Equatable, Sendable, CaseIterable {
    case unknown = -1
    case clearSky = 0
    case mainlyClear = 1
    case partlyCloudy = 2
    case overcast = 3
    case fog = 45
    case rimeFog = 48
    case lightDrizzle = 51
    case drizzle = 53
    case heavyDrizzle = 55
    case lightFreezingDrizzle = 56
    case heavyFreezingDrizzle = 57
    case lightRain = 61
    case rain = 63
    case heavyRain = 65
    case lightFreezingRain = 66
    case heavyFreezingRain = 67
    case lightSnow = 71
    case snow = 73
    case heavySnow = 75
    case snowGrains = 77
    case lightShowers = 80
    case showers = 81
    case heavyShowers = 82
    case lightSnowShowers = 85
    case heavySnowShowers = 86
    case thunderstorm = 95
    case thunderstormWithLightHail = 96
    case thunderstormWithHeavyHail = 99
    
    init(weatherCode: Int) {
        self = Self(rawValue: weatherCode) ?? .unknown
    }

    var displayName: String {
        switch self {
        case .clearSky: return "快晴"
        case .mainlyClear: return "晴"
        case .partlyCloudy: return "晴一部曇"
        case .overcast: return "曇"
        case .fog: return "霧"
        case .rimeFog: return "霜霧"
        case .lightDrizzle: return "弱い霧雨"
        case .drizzle: return "霧雨"
        case .heavyDrizzle: return "強い霧雨"
        case .lightFreezingDrizzle: return "弱い着氷性の霧雨"
        case .heavyFreezingDrizzle: return "強い着氷性の霧雨"
        case .lightRain: return "小雨"
        case .rain: return "雨"
        case .heavyRain: return "大雨"
        case .lightFreezingRain: return "弱い着氷性の雨"
        case .heavyFreezingRain: return "強い着氷性の雨"
        case .lightSnow: return "小雪"
        case .snow: return "雪"
        case .heavySnow: return "大雪"
        case .snowGrains: return "雪粒"
        case .lightShowers: return "弱いにわか雨"
        case .showers: return "にわか雨"
        case .heavyShowers: return "強いにわか雨"
        case .lightSnowShowers: return "弱いにわか雪"
        case .heavySnowShowers: return "強いにわか雪"
        case .thunderstorm: return "雷雨"
        case .thunderstormWithLightHail: return "弱いひょうを伴う雷雨"
        case .thunderstormWithHeavyHail: return "強いひょうを伴う雷雨"
        default: return "不明"
        }
    }

    var emoji: String {
        switch self {
        case .clearSky: return "☀️"
        case .mainlyClear: return "☀️"
        case .partlyCloudy: return "⛅️"
        case .overcast: return "☁️"
        case .fog: return "🌫️"
        case .rimeFog: return "🌫️"
        case .lightDrizzle: return "🌧️"
        case .drizzle: return "🌧️"
        case .heavyDrizzle: return "🌧️"
        case .lightFreezingDrizzle: return "🌧️"
        case .heavyFreezingDrizzle: return "🌧️"
        case .lightRain: return "🌧️"
        case .rain: return "🌧️"
        case .heavyRain: return "🌧️"
        case .lightFreezingRain: return "🌧️"
        case .heavyFreezingRain: return "🌧️"
        case .lightSnow: return "❄️"
        case .snow: return "❄️"
        case .heavySnow: return "❄️"
        case .snowGrains: return "❄️"
        case .lightShowers: return "🌧️"
        case .showers: return "🌧️"
        case .heavyShowers: return "🌧️"
        case .lightSnowShowers: return "❄️"
        case .heavySnowShowers: return "❄️"
        case .thunderstorm: return "⛈️"
        case .thunderstormWithLightHail: return "⛈️"
        case .thunderstormWithHeavyHail: return "⛈️"
        default: return "❓"
        }
    }
}
