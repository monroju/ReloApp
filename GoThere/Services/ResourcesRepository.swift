import Foundation
import FirebaseStorage

/// Fetches public documents from Firebase Storage organized by country.
/// Falls back to sample entries in guest mode or when Storage is empty.
final class ResourcesRepository: ObservableObject {
    static let shared = ResourcesRepository()

    @Published var items: [ResourceItem] = []
    @Published var isLoading = false

    private let storage = Storage.storage()
    private let folders = ["Arrival", "Resources", "Templates", "VisaForms"]

    private init() {}

    @MainActor
    func loadDocuments(for countryId: String) async {
        isLoading = true
        var allItems: [ResourceItem] = []

        // Try Firebase Storage first
        if !AuthService.shared.isGuest {
            for folder in folders {
                let path = "\(folder)/\(countryId)"
                let ref = storage.reference().child(path)
                do {
                    let result = try await ref.listAll()
                    for item in result.items {
                        let url = try? await item.downloadURL()
                        let metadata = try? await item.getMetadata()
                        allItems.append(ResourceItem(
                            name: item.name,
                            path: item.fullPath,
                            sizeBytes: metadata?.size ?? 0,
                            downloadUrl: url?.absoluteString,
                            category: folder
                        ))
                    }
                } catch {
                    // Folder may not exist for this country, skip
                }
            }
        }

        // If no documents found (guest mode or empty Storage), provide samples
        if allItems.isEmpty {
            allItems = sampleDocuments(for: countryId)
        }

        items = allItems
        isLoading = false
    }

    // MARK: - Sample Documents (mirrors Android Firebase Storage structure)

    private func sampleDocuments(for countryId: String) -> [ResourceItem] {
        switch countryId {
        case "spain":
            return [
                ResourceItem(name: "NIE_Application_Form_EX-15.pdf", path: "VisaForms/spain/NIE_Application_Form_EX-15.pdf", sizeBytes: 245_000, downloadUrl: "https://www.inclusion.gob.es/documents/410169/2156469/15-Formulario_NIE_y_certificados.pdf", category: "VisaForms"),
                ResourceItem(name: "Non_Lucrative_Visa_Checklist.pdf", path: "VisaForms/spain/Non_Lucrative_Visa_Checklist.pdf", sizeBytes: 180_000, downloadUrl: "https://www.exteriores.gob.es", category: "VisaForms"),
                ResourceItem(name: "Digital_Nomad_Visa_Guide.pdf", path: "VisaForms/spain/Digital_Nomad_Visa_Guide.pdf", sizeBytes: 320_000, downloadUrl: "https://www.exteriores.gob.es", category: "VisaForms"),
                ResourceItem(name: "Empadronamiento_Guide.pdf", path: "Arrival/spain/Empadronamiento_Guide.pdf", sizeBytes: 150_000, downloadUrl: "https://sede.administracionespublicas.gob.es", category: "Arrival"),
                ResourceItem(name: "Social_Security_Registration.pdf", path: "Arrival/spain/Social_Security_Registration.pdf", sizeBytes: 200_000, downloadUrl: "https://www.seg-social.es", category: "Arrival"),
                ResourceItem(name: "Bank_Account_Opening_Checklist.pdf", path: "Resources/spain/Bank_Account_Opening_Checklist.pdf", sizeBytes: 125_000, downloadUrl: nil, category: "Resources"),
                ResourceItem(name: "Rental_Contract_Template.pdf", path: "Templates/spain/Rental_Contract_Template.pdf", sizeBytes: 280_000, downloadUrl: nil, category: "Templates"),
            ]
        case "portugal":
            return [
                ResourceItem(name: "NIF_Application_Guide.pdf", path: "VisaForms/portugal/NIF_Application_Guide.pdf", sizeBytes: 195_000, downloadUrl: "https://www.portaldasfinancas.gov.pt", category: "VisaForms"),
                ResourceItem(name: "D7_Visa_Checklist.pdf", path: "VisaForms/portugal/D7_Visa_Checklist.pdf", sizeBytes: 210_000, downloadUrl: "https://vistos.mne.gov.pt", category: "VisaForms"),
                ResourceItem(name: "D8_Digital_Nomad_Visa_Guide.pdf", path: "VisaForms/portugal/D8_Digital_Nomad_Visa_Guide.pdf", sizeBytes: 275_000, downloadUrl: "https://www.aima.gov.pt", category: "VisaForms"),
                ResourceItem(name: "SEF_Appointment_Guide.pdf", path: "Arrival/portugal/SEF_Appointment_Guide.pdf", sizeBytes: 165_000, downloadUrl: "https://www.aima.gov.pt", category: "Arrival"),
                ResourceItem(name: "SNS_Health_Registration.pdf", path: "Arrival/portugal/SNS_Health_Registration.pdf", sizeBytes: 140_000, downloadUrl: "https://www.sns.gov.pt", category: "Arrival"),
                ResourceItem(name: "Rental_Contract_Template_PT.pdf", path: "Templates/portugal/Rental_Contract_Template_PT.pdf", sizeBytes: 260_000, downloadUrl: nil, category: "Templates"),
            ]
        case "mexico":
            return [
                ResourceItem(name: "Temporary_Resident_Visa_Checklist.pdf", path: "VisaForms/mexico/Temporary_Resident_Visa_Checklist.pdf", sizeBytes: 230_000, downloadUrl: "https://www.gob.mx/inm", category: "VisaForms"),
                ResourceItem(name: "CURP_Registration_Guide.pdf", path: "VisaForms/mexico/CURP_Registration_Guide.pdf", sizeBytes: 175_000, downloadUrl: "https://www.gob.mx/curp/", category: "VisaForms"),
                ResourceItem(name: "RFC_Tax_ID_Guide.pdf", path: "VisaForms/mexico/RFC_Tax_ID_Guide.pdf", sizeBytes: 190_000, downloadUrl: "https://www.sat.gob.mx", category: "VisaForms"),
                ResourceItem(name: "INM_Card_Exchange_Guide.pdf", path: "Arrival/mexico/INM_Card_Exchange_Guide.pdf", sizeBytes: 155_000, downloadUrl: "https://citas.inm.gob.mx/", category: "Arrival"),
                ResourceItem(name: "IMSS_Enrollment_Guide.pdf", path: "Arrival/mexico/IMSS_Enrollment_Guide.pdf", sizeBytes: 200_000, downloadUrl: "http://www.imss.gob.mx", category: "Arrival"),
                ResourceItem(name: "Rental_Contract_Template_MX.pdf", path: "Templates/mexico/Rental_Contract_Template_MX.pdf", sizeBytes: 245_000, downloadUrl: nil, category: "Templates"),
            ]
        default:
            return []
        }
    }
}
