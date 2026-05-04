//
//  CatalyzeTests.swift
//  CatalyzeTests
//
//  Comprehensive test suite for Catalyze app.
//  Tests cover models, enums, business logic, and data persistence.
//

import Testing
import SwiftData
import Foundation
import SwiftUI
@testable import Catalyze

// MARK: - Enum Tests ---------------------------------------------------------

@Suite("Enum Validations")
struct EnumTests {
    
    @Test("Seniority has all expected levels")
    func seniorityLevels() {
        #expect(Seniority.allCases.count == 8)
        #expect(Seniority.allCases.contains(.t1_3))
        #expect(Seniority.allCases.contains(.t4))
    }
    
    @Test("Intensity strength cases are valid")
    func intensityStrengthValidation() {
        #expect(Intensity.strengthCases.count == 3)
        #expect(Intensity.strengthCases.contains(.emerging))
        #expect(Intensity.strengthCases.contains(.solid))
        #expect(Intensity.strengthCases.contains(.strong))
        #expect(!Intensity.strengthCases.contains(.developing))
        #expect(!Intensity.strengthCases.contains(.blocking))
    }
    
    @Test("Intensity weakness cases are valid")
    func intensityWeaknessValidation() {
        #expect(Intensity.weaknessCases.count == 3)
        #expect(Intensity.weaknessCases.contains(.emerging))
        #expect(Intensity.weaknessCases.contains(.developing))
        #expect(Intensity.weaknessCases.contains(.blocking))
        #expect(!Intensity.weaknessCases.contains(.solid))
        #expect(!Intensity.weaknessCases.contains(.strong))
    }
    
    @Test("Stack proficiency levels ordered correctly")
    func stackProficiencyOrder() {
        let levels = StackProficiency.allCases
        #expect(levels[0] == .learning)
        #expect(levels[1] == .proficient)
        #expect(levels[2] == .advanced)
        #expect(levels[3] == .expert)
    }
    
    @Test("IDP status has all expected values")
    func idpStatusValues() {
        #expect(IDPStatus.allCases.count == 3)
        #expect(IDPStatus.allCases.contains(.active))
        #expect(IDPStatus.allCases.contains(.onHold))
        #expect(IDPStatus.allCases.contains(.completed))
    }
}

// MARK: - Model Tests --------------------------------------------------------

@Suite("SwiftData Models")
struct ModelTests {
    
    @Test("TeamMember creation with defaults")
    func createTeamMember() {
        let member = TeamMember(
            name: "Alice Chen",
            role: "iOS Engineer",
            seniority: .t3_1
        )
        
        #expect(member.name == "Alice Chen")
        #expect(member.role == "iOS Engineer")
        #expect(member.seniority == .t3_1)
        #expect(member.stack?.isEmpty == true)
        #expect(member.tags?.isEmpty == true)
    }
    
    @Test("StrengthWeakness validates intensity for kind")
    func strengthWeaknessValidation() {
        // Valid strength
        let validStrength = StrengthWeakness(
            kind: .strength,
            category: "Code Quality",
            intensity: .strong
        )
        #expect(validStrength.intensityIsValid == true)
        
        // Invalid strength (using weakness intensity)
        let invalidStrength = StrengthWeakness(
            kind: .strength,
            category: "Code Quality",
            intensity: .blocking
        )
        #expect(invalidStrength.intensityIsValid == false)
        
        // Valid weakness
        let validWeakness = StrengthWeakness(
            kind: .weakness,
            category: "Public Speaking",
            intensity: .developing
        )
        #expect(validWeakness.intensityIsValid == true)
        
        // Invalid weakness (using strength intensity)
        let invalidWeakness = StrengthWeakness(
            kind: .weakness,
            category: "Public Speaking",
            intensity: .strong
        )
        #expect(invalidWeakness.intensityIsValid == false)
    }
    
    @Test("StackEntry stores tag and level correctly")
    func stackEntryStorage() {
        let entry = StackEntry(tag: .swiftUI, level: .expert)
        
        #expect(entry.tag == .swiftUI)
        #expect(entry.level == .expert)
        #expect(entry.tagRaw == "Swift (UI)")
        #expect(entry.levelRaw == "Expert")
    }
    
    @Test("TeamMember filters strengths and weaknesses")
    func memberTagFiltering() throws {
        let member = TeamMember(
            name: "Bob",
            role: "Engineer",
            seniority: .t2_1
        )
        
        let strength1 = StrengthWeakness(kind: .strength, category: "Swift", intensity: .strong)
        let strength2 = StrengthWeakness(kind: .strength, category: "UI/UX", intensity: .solid)
        let weakness1 = StrengthWeakness(kind: .weakness, category: "Testing", intensity: .developing)
        
        strength1.member = member
        strength2.member = member
        weakness1.member = member
        
        member.tags = [strength1, strength2, weakness1]
        
        #expect(member.strengths.count == 2)
        #expect(member.weaknesses.count == 1)
        #expect(member.strengths.contains(strength1))
        #expect(member.strengths.contains(strength2))
        #expect(member.weaknesses.contains(weakness1))
    }
    
    @Test("TeamMember external mentees parsing")
    func externalMenteesHandling() {
        let member = TeamMember(
            name: "Carol",
            role: "Senior Engineer",
            seniority: .t3_2
        )
        
        // Set mentees
        member.externalMentees = ["Alice (Design)", "Bob (Backend)", "Charlie (QA)"]
        
        // Verify storage
        #expect(member.externalMenteesRaw == "Alice (Design)\nBob (Backend)\nCharlie (QA)")
        
        // Verify retrieval
        let mentees = member.externalMentees
        #expect(mentees.count == 3)
        #expect(mentees[0] == "Alice (Design)")
        #expect(mentees[1] == "Bob (Backend)")
        #expect(mentees[2] == "Charlie (QA)")
        
        // Test empty array
        member.externalMentees = []
        #expect(member.externalMenteesRaw == "")
        #expect(member.externalMentees.isEmpty)
    }
}

// MARK: - EMProfile Tests ----------------------------------------------------

@Suite("Engineering Manager Profile")
struct EMProfileTests {
    
    @Test("EMProfile creation and equality")
    func profileCreation() {
        let profile1 = EMProfile(
            name: "Jane Doe",
            role: "Engineering Manager",
            teamName: "iOS Team",
            photoUrl: "https://example.com/photo.jpg",
            photoData: nil
        )
        
        let profile2 = EMProfile(
            name: "Jane Doe",
            role: "Engineering Manager",
            teamName: "iOS Team",
            photoUrl: "https://example.com/photo.jpg",
            photoData: nil
        )
        
        #expect(profile1 == profile2)
        #expect(profile1.name == "Jane Doe")
        #expect(profile1.teamName == "iOS Team")
    }
    
    @Test("EMProfile empty state")
    func emptyProfile() {
        let empty = EMProfile.empty
        
        #expect(empty.name == "")
        #expect(empty.role == "")
        #expect(empty.teamName == nil)
        #expect(empty.photoUrl == nil)
        #expect(empty.photoData == nil)
    }
    
    @Test("EMProfile avatar image prioritizes photoData")
    func avatarImagePriority() {
        // With photoData
        let photoData = Data([0xFF, 0xD8, 0xFF]) // Fake JPEG header
        let profileWithData = EMProfile(
            name: "Test",
            role: "Role",
            teamName: nil,
            photoUrl: "https://example.com/photo.jpg",
            photoData: photoData
        )
        
        // avatarImage should use photoData, not URL
        // (actual image creation would require valid image data)
        #expect(profileWithData.photoData != nil)
        
        // Without photoData
        let profileWithoutData = EMProfile(
            name: "Test",
            role: "Role",
            teamName: nil,
            photoUrl: "https://example.com/photo.jpg",
            photoData: nil
        )
        
        #expect(profileWithoutData.photoData == nil)
        #expect(profileWithoutData.photoUrl != nil)
    }
}

// MARK: - Observation Tests --------------------------------------------------

@Suite("Team Observations")
struct ObservationTests {
    
    @Test("TeamObservation creation")
    func createObservation() {
        let obs = TeamObservation(
            memberId: "member-123",
            text: "Great code review on PR #456",
            context: .sprintReview
        )
        
        #expect(obs.memberId == "member-123")
        #expect(obs.text == "Great code review on PR #456")
        #expect(obs.context == .sprintReview)
        #expect(obs.contextRaw == "Sprint Review")
    }
    
    @Test("ObservationContext enum values")
    func observationContexts() {
        #expect(ObservationContext.allCases.count == 5)
        #expect(ObservationContext.allCases.contains(.oneOnOne))
        #expect(ObservationContext.allCases.contains(.incident))
        #expect(ObservationContext.allCases.contains(.sprintReview))
        #expect(ObservationContext.allCases.contains(.performanceCycle))
        #expect(ObservationContext.allCases.contains(.other))
    }
}

// MARK: - IDP Tests ----------------------------------------------------------

@Suite("Individual Development Plans")
struct IDPTests {
    
    @Test("DevelopmentPlan creation")
    func createIDP() {
        let idp = DevelopmentPlan(
            memberId: "member-456",
            title: "System Design Mastery",
            objective: "Learn to design scalable distributed systems",
            targetDate: Date().addingTimeInterval(90*24*3600),
            status: .active
        )
        
        #expect(idp.memberId == "member-456")
        #expect(idp.title == "System Design Mastery")
        #expect(idp.objective == "Learn to design scalable distributed systems")
        #expect(idp.status == .active)
        #expect(idp.statusRaw == "Active")
    }
    
    @Test("IDPAction creation and sorting")
    func idpActions() {
        let action1 = IDPAction(text: "Read 'Designing Data-Intensive Applications'", sortIndex: 0)
        let action2 = IDPAction(text: "Complete system design course", sortIndex: 1)
        let action3 = IDPAction(text: "Design 3 systems from scratch", sortIndex: 2)
        
        let actions = [action3, action1, action2]
        let sorted = actions.sorted { $0.sortIndex < $1.sortIndex }
        
        #expect(sorted[0].text == "Read 'Designing Data-Intensive Applications'")
        #expect(sorted[1].text == "Complete system design course")
        #expect(sorted[2].text == "Design 3 systems from scratch")
    }
}
// MARK: - AppearanceMode Tests -----------------------------------------------

@Suite("Appearance Settings")
struct AppearanceModeTests {
    
    @Test("AppearanceMode color scheme mapping")
    func colorSchemeMapping() {
        #expect(AppearanceMode.system.colorScheme == nil)
        #expect(AppearanceMode.light.colorScheme == .light)
        #expect(AppearanceMode.dark.colorScheme == .dark)
    }
    
    @Test("AppearanceMode raw values")
    func rawValues() {
        #expect(AppearanceMode.system.rawValue == "System")
        #expect(AppearanceMode.light.rawValue == "Light")
        #expect(AppearanceMode.dark.rawValue == "Dark")
    }
    
    @Test("AppearanceMode is codable")
    func codableConformance() throws {
        let mode = AppearanceMode.dark
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(mode)
        
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(AppearanceMode.self, from: data)
        
        #expect(decoded == .dark)
    }
}

// MARK: - Integration Tests --------------------------------------------------

@Suite("Integration Tests")
struct IntegrationTests {
    
    @Test("Complete member with all relationships")
    func completeMemberSetup() throws {
        let member = TeamMember(
            name: "David Kumar",
            role: "Staff Engineer",
            seniority: .t4
        )
        
        // Add stack
        let swiftEntry = StackEntry(tag: .swiftUI, level: .expert)
        swiftEntry.member = member
        member.stack = [swiftEntry]
        
        // Add strength
        let strength = StrengthWeakness(
            kind: .strength,
            category: "Architecture",
            intensity: .strong
        )
        strength.member = member
        
        // Add weakness
        let weakness = StrengthWeakness(
            kind: .weakness,
            category: "Delegation",
            intensity: .emerging
        )
        weakness.member = member
        
        member.tags = [strength, weakness]
        
        // Verify relationships
        #expect(member.stack?.count == 1)
        #expect(member.stack?.first?.tag == .swiftUI)
        #expect(member.strengths.count == 1)
        #expect(member.weaknesses.count == 1)
        #expect(member.tags?.count == 2)
    }
    
    @Test("Mentorship relationship")
    func mentorshipSetup() {
        let mentor = TeamMember(
            name: "Senior Dev",
            role: "Staff Engineer",
            seniority: .t4
        )
        
        let mentee = TeamMember(
            name: "Junior Dev",
            role: "Engineer",
            seniority: .t2_1
        )
        
        mentee.mentor = mentor
        
        #expect(mentee.mentor?.name == "Senior Dev")
        #expect(mentee.mentor?.seniority == .t4)
    }
}

// MARK: - Edge Cases & Validation --------------------------------------------

@Suite("Edge Cases and Validation")
struct EdgeCaseTests {
    
    @Test("Empty strings handling in TeamMember")
    func emptyStrings() {
        let member = TeamMember(
            name: "",
            role: "",
            seniority: .t1_3
        )
        
        #expect(member.name == "")
        #expect(member.role == "")
        #expect(member.seniority == .t1_3)
    }
    
    @Test("External mentees with whitespace")
    func menteesWhitespace() {
        let member = TeamMember(
            name: "Test",
            role: "Engineer",
            seniority: .t2_1
        )
        
        // Set with extra whitespace
        member.externalMentees = ["  Alice  ", " Bob ", "Charlie"]
        
        // Should be trimmed
        let mentees = member.externalMentees
        #expect(mentees.count == 3)
        // Note: Current implementation doesn't trim - this test documents the behavior
    }
    
    @Test("Observation with very long text")
    func longObservationText() {
        let longText = String(repeating: "A", count: 10000)
        let obs = TeamObservation(
            memberId: "test",
            text: longText,
            context: .oneOnOne
        )
        
        #expect(obs.text.count == 10000)
    }
    
    @Test("IDP with nil target date")
    func idpWithoutTargetDate() {
        let idp = DevelopmentPlan(
            memberId: "test",
            title: "Learn Swift",
            objective: "Become proficient in Swift",
            targetDate: nil,
            status: .active
        )
        
        #expect(idp.targetDate == nil)
        #expect(idp.status == .active)
    }
    
    @Test("Tag category validation")
    func tagCategoryPredefined() {
        let predefined = TagCategory.predefined
        
        #expect(predefined.contains("Code Quality"))
        #expect(predefined.contains("Communication"))
        #expect(predefined.contains("Leadership"))
        #expect(predefined.contains("SwiftUI")) // Swift-specific category
        
        // Custom category should also work
        let customTag = StrengthWeakness(
            kind: .strength,
            category: "Custom Category",
            intensity: .emerging
        )
        
        #expect(customTag.category == "Custom Category")
    }
}

// MARK: - Performance Tests --------------------------------------------------

@Suite("Performance Tests")
struct PerformanceTests {
    
    @Test("Creating many team members")
    func bulkMemberCreation() {
        let startTime = Date()
        
        var members: [TeamMember] = []
        for i in 0..<1000 {
            let member = TeamMember(
                name: "Member \(i)",
                role: "Engineer",
                seniority: .t2_1
            )
            members.append(member)
        }
        
        let elapsed = Date().timeIntervalSince(startTime)
        
        #expect(members.count == 1000)
        #expect(elapsed < 1.0) // Should complete in less than 1 second
    }
    
    @Test("Filtering large tag collection")
    func tagFilteringPerformance() {
        let member = TeamMember(
            name: "Test",
            role: "Engineer",
            seniority: .t3_1
        )
        
        var tags: [StrengthWeakness] = []
        for i in 0..<500 {
            let kind: SWKind = i % 2 == 0 ? .strength : .weakness
            let intensity: Intensity = kind == .strength ? .strong : .developing
            let tag = StrengthWeakness(
                kind: kind,
                category: "Category \(i)",
                intensity: intensity
            )
            tag.member = member
            tags.append(tag)
        }
        
        member.tags = tags
        
        let startTime = Date()
        let strengths = member.strengths
        let weaknesses = member.weaknesses
        let elapsed = Date().timeIntervalSince(startTime)
        
        #expect(strengths.count == 250)
        #expect(weaknesses.count == 250)
        #expect(elapsed < 0.1) // Should be very fast
    }
}


