import Foundation
import Vapor

// MARK: - Core User Roles & Auth
public enum UserRole: String, Codable, CaseIterable, Sendable {
    case patient = "patient"
    case clinician = "clinician"
    case parentGuardian = "parent_guardian"
    case authorizedFamilyMember = "authorized_family_member"
    case administrator = "administrator"
}

public struct UserProfile: Content, Sendable {
    public let id: String
    public let email: String
    public let name: String
    public let role: UserRole
    public let createdAt: String

    public init(id: String, email: String, name: String, role: UserRole, createdAt: String = ISO8601DateFormatter().string(from: Date())) {
        self.id = id
        self.email = email
        self.name = name
        self.role = role
        self.createdAt = createdAt
    }
}

public struct AuthResponse: Content, Sendable {
    public let token: String
    public let user: UserProfile
}

// MARK: - Patient Lab Record
public struct LabResultRecord: Content, Sendable {
    public let id: String
    public let patientId: String
    public let testDate: String
    public let labName: String
    public let tsh: Double
    public let freeT4: Double?
    public let freeT3: Double?
    public let totalT4: Double?
    public let totalT3: Double?
    public let tpoAb: Double?
    public let tgAb: Double?
    public let traB: Double?
    public let reverseT3: Double?
    public let referenceRangeTSH: String
    public let units: String
    public let reportURL: String?
    public let clinicianNotes: String?

    public init(
        id: String = UUID().uuidString,
        patientId: String,
        testDate: String,
        labName: String = "Quest Diagnostics",
        tsh: Double,
        freeT4: Double? = nil,
        freeT3: Double? = nil,
        totalT4: Double? = nil,
        totalT3: Double? = nil,
        tpoAb: Double? = nil,
        tgAb: Double? = nil,
        traB: Double? = nil,
        reverseT3: Double? = nil,
        referenceRangeTSH: String = "0.45 - 4.50 mIU/L",
        units: String = "mIU/L",
        reportURL: String? = nil,
        clinicianNotes: String? = nil
    ) {
        self.id = id
        self.patientId = patientId
        self.testDate = testDate
        self.labName = labName
        self.tsh = tsh
        self.freeT4 = freeT4
        self.freeT3 = freeT3
        self.totalT4 = totalT4
        self.totalT3 = totalT3
        self.tpoAb = tpoAb
        self.tgAb = tgAb
        self.traB = traB
        self.reverseT3 = reverseT3
        self.referenceRangeTSH = referenceRangeTSH
        self.units = units
        self.reportURL = reportURL
        self.clinicianNotes = clinicianNotes
    }
}

// MARK: - Food Log Entry & Interaction Layer
public struct IdentifiedFoodItem: Content, Sendable {
    public let food: String
    public let confidence: Double
    public let identifiedCompounds: [String]
    public let usdaSource: String
    public let clinicalInterpretation: String

    public init(food: String, confidence: Double, identifiedCompounds: [String], usdaSource: String = "USDA FoodData Central", clinicalInterpretation: String) {
        self.food = food
        self.confidence = confidence
        self.identifiedCompounds = identifiedCompounds
        self.usdaSource = usdaSource
        self.clinicalInterpretation = clinicalInterpretation
    }
}

public struct FoodLogRecord: Content, Sendable {
    public let id: String
    public let patientId: String
    public let timestamp: String
    public let mealName: String
    public let imageURL: String?
    public let identifiedFoods: [IdentifiedFoodItem]
    public let safetyDisclaimer: String

    public init(
        id: String = UUID().uuidString,
        patientId: String,
        timestamp: String = ISO8601DateFormatter().string(from: Date()),
        mealName: String,
        imageURL: String? = nil,
        identifiedFoods: [IdentifiedFoodItem],
        safetyDisclaimer: String = "Potential dietary factor only. Food interactions may influence absorption but are not evidence of direct TSH causation."
    ) {
        self.id = id
        self.patientId = patientId
        self.timestamp = timestamp
        self.mealName = mealName
        self.imageURL = imageURL
        self.identifiedFoods = identifiedFoods
        self.safetyDisclaimer = safetyDisclaimer
    }
}

// MARK: - Structured Medication Log
public struct MedicationRecord: Content, Sendable {
    public let id: String
    public let patientId: String
    public let name: String
    public let genericName: String
    public let dose: String
    public let unit: String
    public let frequency: String
    public let route: String
    public let startDate: String
    public let stopDate: String?
    public let isActive: Bool
    public let timeOfDay: String
    public let prescribingClinician: String?
    public let notes: String?
    public let interactionNotes: String?
    public let safetyDisclaimer: String

    public init(
        id: String = UUID().uuidString,
        patientId: String,
        name: String,
        genericName: String,
        dose: String,
        unit: String = "mcg",
        frequency: String = "Daily",
        route: String = "Oral",
        startDate: String,
        stopDate: String? = nil,
        isActive: Bool = true,
        timeOfDay: String = "07:00 AM",
        prescribingClinician: String? = nil,
        notes: String? = nil,
        interactionNotes: String? = nil,
        safetyDisclaimer: String = "Medication interactions may affect thyroid laboratory results. Discuss any medication changes with your clinician."
    ) {
        self.id = id
        self.patientId = patientId
        self.name = name
        self.genericName = genericName
        self.dose = dose
        self.unit = unit
        self.frequency = frequency
        self.route = route
        self.startDate = startDate
        self.stopDate = stopDate
        self.isActive = isActive
        self.timeOfDay = timeOfDay
        self.prescribingClinician = prescribingClinician
        self.notes = notes
        self.interactionNotes = interactionNotes
        self.safetyDisclaimer = safetyDisclaimer
    }
}

// MARK: - Patient Timeline Engine Event
public struct TimelineEvent: Content, Sendable {
    public let id: String
    public let patientId: String
    public let date: String
    public let category: String // "lab", "medication", "food", "symptom", "appointment", "ai_observation"
    public let title: String
    public let summary: String
    public let details: String?

    public init(id: String = UUID().uuidString, patientId: String, date: String, category: String, title: String, summary: String, details: String? = nil) {
        self.id = id
        self.patientId = patientId
        self.date = date
        self.category = category
        self.title = title
        self.summary = summary
        self.details = details
    }
}

// MARK: - Thyroid Trend Engine Output
public enum TrendDirection: String, Codable, Sendable {
    case stable = "Stable"
    case graduallyIncreasing = "Gradually Increasing"
    case graduallyDecreasing = "Gradually Decreasing"
    case significantIncrease = "Significant Increase"
    case significantDecrease = "Significant Decrease"
    case highlyVariable = "Highly Variable"
    case insufficientData = "Insufficient Data"
}

public struct ThyroidTrendAnalysis: Content, Sendable {
    public let patientId: String
    public let latestTSH: Double
    public let previousTSH: Double?
    public let absoluteChange: Double
    public let percentChange: Double
    public let rateOfChangePerMonth: Double
    public let direction: TrendDirection
    public let movingAverageTSH: Double
    public let highestTSH: Double
    public let lowestTSH: Double
    public let totalLabCount: Int
    public let summary: String

    public init(
        patientId: String,
        latestTSH: Double,
        previousTSH: Double?,
        absoluteChange: Double,
        percentChange: Double,
        rateOfChangePerMonth: Double,
        direction: TrendDirection,
        movingAverageTSH: Double,
        highestTSH: Double,
        lowestTSH: Double,
        totalLabCount: Int,
        summary: String
    ) {
        self.patientId = patientId
        self.latestTSH = latestTSH
        self.previousTSH = previousTSH
        self.absoluteChange = absoluteChange
        self.percentChange = percentChange
        self.rateOfChangePerMonth = rateOfChangePerMonth
        self.direction = direction
        self.movingAverageTSH = movingAverageTSH
        self.highestTSH = highestTSH
        self.lowestTSH = lowestTSH
        self.totalLabCount = totalLabCount
        self.summary = summary
    }
}

// MARK: - Critical Change Point Event
public struct ClinicalReviewEvent: Content, Sendable {
    public let id: String
    public let patientId: String
    public let eventType: String // "TSH_RAPID_INCREASE", "TSH_REVERSAL", "ABNORMAL_LAB_ENTERED"
    public let previousValue: Double
    public let newValue: Double
    public let daysBetween: Int
    public let severity: String // "review_recommended", "high_priority", "routine"
    public let status: String // "pending", "reviewed", "dismissed"
    public let createdAt: String
    public var clinicianPrivateNotes: String?
    public var patientVisibleNotes: String?
    public var requestedLabs: String?
    public var recommendedAppointment: String?

    public init(
        id: String = UUID().uuidString,
        patientId: String,
        eventType: String,
        previousValue: Double,
        newValue: Double,
        daysBetween: Int,
        severity: String = "review_recommended",
        status: String = "pending",
        createdAt: String = ISO8601DateFormatter().string(from: Date()),
        clinicianPrivateNotes: String? = nil,
        patientVisibleNotes: String? = nil,
        requestedLabs: String? = nil,
        recommendedAppointment: String? = nil
    ) {
        self.id = id
        self.patientId = patientId
        self.eventType = eventType
        self.previousValue = previousValue
        self.newValue = newValue
        self.daysBetween = daysBetween
        self.severity = severity
        self.status = status
        self.createdAt = createdAt
        self.clinicianPrivateNotes = clinicianPrivateNotes
        self.patientVisibleNotes = patientVisibleNotes
        self.requestedLabs = requestedLabs
        self.recommendedAppointment = recommendedAppointment
    }
}

// MARK: - Consent & Permissions
public enum ClinicianPermissionLevel: String, Codable, Sendable {
    case summaryOnly = "SUMMARY_ONLY"
    case labHistory = "LAB_HISTORY"
    case reportAccess = "REPORT_ACCESS"
    case fullClinicalView = "FULL_CLINICAL_VIEW"
}

public struct ClinicianConsentRecord: Content, Sendable {
    public let id: String
    public let patientId: String
    public let clinicianId: String
    public let clinicianName: String
    public let permissionLevel: ClinicianPermissionLevel
    public let status: String // "active", "revoked"
    public let grantedAt: String
    public var revokedAt: String?

    public init(
        id: String = UUID().uuidString,
        patientId: String,
        clinicianId: String,
        clinicianName: String,
        permissionLevel: ClinicianPermissionLevel = .summaryOnly,
        status: String = "active",
        grantedAt: String = ISO8601DateFormatter().string(from: Date()),
        revokedAt: String? = nil
    ) {
        self.id = id
        self.patientId = patientId
        self.clinicianId = clinicianId
        self.clinicianName = clinicianName
        self.permissionLevel = permissionLevel
        self.status = status
        self.grantedAt = grantedAt
        self.revokedAt = revokedAt
    }
}

// MARK: - Family Account & Links
public enum FamilyPermissionLevel: String, Codable, Sendable {
    case viewSummary = "VIEW_SUMMARY"
    case viewLabs = "VIEW_LABS"
    case viewMedications = "VIEW_MEDICATIONS"
    case viewFood = "VIEW_FOOD"
    case viewReports = "VIEW_REPORTS"
    case manageProfile = "MANAGE_PROFILE"
    case guardianFullAccess = "GUARDIAN_FULL_ACCESS"
}

public struct FamilyLinkRecord: Content, Sendable {
    public let id: String
    public let ownerUserId: String
    public let linkedUserId: String
    public let linkedUserName: String
    public let relationship: String // "Child", "Mother", "Father", "Spouse", "Sibling"
    public let permissionLevel: FamilyPermissionLevel
    public let grantedAt: String

    public init(
        id: String = UUID().uuidString,
        ownerUserId: String,
        linkedUserId: String,
        linkedUserName: String,
        relationship: String,
        permissionLevel: FamilyPermissionLevel = .viewSummary,
        grantedAt: String = ISO8601DateFormatter().string(from: Date())
    ) {
        self.id = id
        self.ownerUserId = ownerUserId
        self.linkedUserId = linkedUserId
        self.linkedUserName = linkedUserName
        self.relationship = relationship
        self.permissionLevel = permissionLevel
        self.grantedAt = grantedAt
    }
}

// MARK: - Provider / Endocrinologist Search
public struct EndocrinologistProvider: Content, Sendable {
    public let id: String
    public let name: String
    public let specialty: String
    public let distanceMiles: Double
    public let rating: Double
    public let reviewCount: Int
    public let address: String
    public let phone: String
    public let website: String
    public let directionsURL: String
    public let bookingURL: String

    public init(
        id: String = UUID().uuidString,
        name: String,
        specialty: String = "Endocrinology & Thyroid Care",
        distanceMiles: Double,
        rating: Double,
        reviewCount: Int,
        address: String,
        phone: String,
        website: String,
        directionsURL: String,
        bookingURL: String
    ) {
        self.id = id
        self.name = name
        self.specialty = specialty
        self.distanceMiles = distanceMiles
        self.rating = rating
        self.reviewCount = reviewCount
        self.address = address
        self.phone = phone
        self.website = website
        self.directionsURL = directionsURL
        self.bookingURL = bookingURL
    }
}

// MARK: - Thyroid Report & Versioning
public struct GeneratedReportRecord: Content, Sendable {
    public let reportId: String
    public let patientId: String
    public let patientName: String
    public let createdAt: String
    public let dateRange: String
    public let version: Int
    public let contentHash: String
    public let shareToken: String
    public let expiresAt: String
    public let summaryText: String
    public let htmlReport: String

    public init(
        reportId: String = UUID().uuidString,
        patientId: String,
        patientName: String,
        createdAt: String = ISO8601DateFormatter().string(from: Date()),
        dateRange: String,
        version: Int = 1,
        contentHash: String,
        shareToken: String = UUID().uuidString,
        expiresAt: String = ISO8601DateFormatter().string(from: Date().addingTimeInterval(86400 * 7)),
        summaryText: String,
        htmlReport: String
    ) {
        self.reportId = reportId
        self.patientId = patientId
        self.patientName = patientName
        self.createdAt = createdAt
        self.dateRange = dateRange
        self.version = version
        self.contentHash = contentHash
        self.shareToken = shareToken
        self.expiresAt = expiresAt
        self.summaryText = summaryText
        self.htmlReport = htmlReport
    }
}

// MARK: - AI Clinical Summary
public struct AICinicalSummary: Content, Sendable {
    public let trendSummary: String
    public let majorChanges: [String]
    public let possibleAssociations: [String]
    public let questionsForClinician: [String]
    public let confidence: Double
    public let safetyDisclaimer: String

    public init(
        trendSummary: String,
        majorChanges: [String],
        possibleAssociations: [String],
        questionsForClinician: [String],
        confidence: Double = 0.88,
        safetyDisclaimer: String = "ThyroCare does not diagnose thyroid conditions or replace clinical care. All observations must be evaluated by a healthcare professional."
    ) {
        self.trendSummary = trendSummary
        self.majorChanges = majorChanges
        self.possibleAssociations = possibleAssociations
        self.questionsForClinician = questionsForClinician
        self.confidence = confidence
        self.safetyDisclaimer = safetyDisclaimer
    }
}

// MARK: - Audit Log
public struct AuditLogEntry: Content, Sendable {
    public let id: String
    public let actorUserId: String
    public let actorRole: UserRole
    public let patientId: String
    public let resourceType: String
    public let action: String
    public let timestamp: String
    public let ipMetadata: String

    public init(
        id: String = UUID().uuidString,
        actorUserId: String,
        actorRole: UserRole,
        patientId: String,
        resourceType: String,
        action: String,
        timestamp: String = ISO8601DateFormatter().string(from: Date()),
        ipMetadata: String = "127.0.0.1"
    ) {
        self.id = id
        self.actorUserId = actorUserId
        self.actorRole = actorRole
        self.patientId = patientId
        self.resourceType = resourceType
        self.action = action
        self.timestamp = timestamp
        self.ipMetadata = ipMetadata
    }
}
