import Foundation
import FirebaseCore
import FirebaseStorage

/// Fetches public documents from Firebase Storage organized by country.
/// Falls back to sample entries in guest mode or when Storage is empty.
final class ResourcesRepository: ObservableObject {
    static let shared = ResourcesRepository()

    @Published var items: [ResourceItem] = []
    @Published var isLoading = false

    private lazy var storage = Storage.storage()
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
        case "canada":
            return [
                ResourceItem(name: "Bill_C3_Citizenship_Application_Guide.pdf", path: "VisaForms/canada/Bill_C3_Citizenship_Application_Guide.pdf", sizeBytes: 240_000, downloadUrl: "https://www.canada.ca/en/immigration-refugees-citizenship/services/canadian-citizenship/proof-citizenship.html", category: "VisaForms"),
                ResourceItem(name: "Proof_of_Canadian_Ancestor_Checklist.pdf", path: "VisaForms/canada/Proof_of_Canadian_Ancestor_Checklist.pdf", sizeBytes: 185_000, downloadUrl: "https://www.canada.ca/en/immigration-refugees-citizenship.html", category: "VisaForms"),
                ResourceItem(name: "Citizenship_Certificate_Application_CIT0001.pdf", path: "VisaForms/canada/Citizenship_Certificate_Application_CIT0001.pdf", sizeBytes: 210_000, downloadUrl: "https://www.canada.ca/en/immigration-refugees-citizenship/corporate/publications-manuals/operational-bulletins-manuals/canadian-citizenship.html", category: "VisaForms"),
                ResourceItem(name: "SIN_Application_Guide.pdf", path: "Arrival/canada/SIN_Application_Guide.pdf", sizeBytes: 160_000, downloadUrl: "https://www.canada.ca/en/employment-social-development/services/sin.html", category: "Arrival"),
                ResourceItem(name: "Provincial_Healthcare_Registration.pdf", path: "Arrival/canada/Provincial_Healthcare_Registration.pdf", sizeBytes: 195_000, downloadUrl: "https://www.canada.ca/en/health-canada/services/health-care-system/canada-health-care-system-medicare.html", category: "Arrival"),
                ResourceItem(name: "Rental_Contract_Template_CA.pdf", path: "Templates/canada/Rental_Contract_Template_CA.pdf", sizeBytes: 255_000, downloadUrl: nil, category: "Templates"),
            ]
        case "ireland":
            return [
                ResourceItem(name: "Foreign_Births_Register_Application.pdf", path: "VisaForms/ireland/Foreign_Births_Register_Application.pdf", sizeBytes: 220_000, downloadUrl: "https://www.ireland.ie/en/dfa/citizenship/born-abroad/", category: "VisaForms"),
                ResourceItem(name: "FBR_Required_Documents_Checklist.pdf", path: "VisaForms/ireland/FBR_Required_Documents_Checklist.pdf", sizeBytes: 175_000, downloadUrl: "https://www.ireland.ie/en/dfa/citizenship/", category: "VisaForms"),
                ResourceItem(name: "Apostille_Translation_Guide_IE.pdf", path: "Resources/ireland/Apostille_Translation_Guide_IE.pdf", sizeBytes: 145_000, downloadUrl: "https://www.dfa.ie/passports/the-apostille-and-authentication-service/", category: "Resources"),
                ResourceItem(name: "PPS_Number_Registration_Guide.pdf", path: "Arrival/ireland/PPS_Number_Registration_Guide.pdf", sizeBytes: 165_000, downloadUrl: "https://www.gov.ie/en/service/12e6de-get-a-personal-public-service-pps-number/", category: "Arrival"),
                ResourceItem(name: "HSE_Healthcare_Registration.pdf", path: "Arrival/ireland/HSE_Healthcare_Registration.pdf", sizeBytes: 180_000, downloadUrl: "https://www2.hse.ie/services/medical-cards/", category: "Arrival"),
                ResourceItem(name: "Rental_Contract_Template_IE.pdf", path: "Templates/ireland/Rental_Contract_Template_IE.pdf", sizeBytes: 240_000, downloadUrl: nil, category: "Templates"),
            ]
        case "italy":
            return [
                ResourceItem(name: "Jure_Sanguinis_Document_Checklist.pdf", path: "VisaForms/italy/Jure_Sanguinis_Document_Checklist.pdf", sizeBytes: 250_000, downloadUrl: "https://www.esteri.it/en/servizi-consolari-e-visti/italiani-all-estero/cittadinanza/", category: "VisaForms"),
                ResourceItem(name: "Consulate_Appointment_Booking_Guide.pdf", path: "VisaForms/italy/Consulate_Appointment_Booking_Guide.pdf", sizeBytes: 165_000, downloadUrl: "https://prenotami.esteri.it/", category: "VisaForms"),
                ResourceItem(name: "1948_Case_Court_Route_Guide.pdf", path: "Resources/italy/1948_Case_Court_Route_Guide.pdf", sizeBytes: 195_000, downloadUrl: "https://www.esteri.it/en/", category: "Resources"),
                ResourceItem(name: "Apostille_and_Sworn_Translation_Guide_IT.pdf", path: "Resources/italy/Apostille_and_Sworn_Translation_Guide_IT.pdf", sizeBytes: 175_000, downloadUrl: "https://www.esteri.it/en/", category: "Resources"),
                ResourceItem(name: "Codice_Fiscale_Application.pdf", path: "Arrival/italy/Codice_Fiscale_Application.pdf", sizeBytes: 155_000, downloadUrl: "https://www.agenziaentrate.gov.it/portale/codice-fiscale-tessera-sanitaria", category: "Arrival"),
                ResourceItem(name: "Anagrafe_Registration_Guide.pdf", path: "Arrival/italy/Anagrafe_Registration_Guide.pdf", sizeBytes: 145_000, downloadUrl: "https://www.anagrafenazionale.interno.it/", category: "Arrival"),
                ResourceItem(name: "Rental_Contract_Template_IT.pdf", path: "Templates/italy/Rental_Contract_Template_IT.pdf", sizeBytes: 245_000, downloadUrl: nil, category: "Templates"),
            ]
        case "germany":
            return [
                ResourceItem(name: "BVA_Antrag_Article_116_Form.pdf", path: "VisaForms/germany/BVA_Antrag_Article_116_Form.pdf", sizeBytes: 215_000, downloadUrl: "https://www.bva.bund.de/EN/Services/Citizens/Migration-Citizenship/Citizenship/Restoration-of-citizenship/restoration-of-citizenship_node.html", category: "VisaForms"),
                ResourceItem(name: "StAG_15_Application_Form.pdf", path: "VisaForms/germany/StAG_15_Application_Form.pdf", sizeBytes: 205_000, downloadUrl: "https://www.bva.bund.de/EN/Services/Citizens/Migration-Citizenship/Citizenship/Restoration-of-citizenship/restoration-of-citizenship_node.html", category: "VisaForms"),
                ResourceItem(name: "Article_116_Eligibility_Checklist.pdf", path: "Resources/germany/Article_116_Eligibility_Checklist.pdf", sizeBytes: 165_000, downloadUrl: "https://www.bva.bund.de/", category: "Resources"),
                ResourceItem(name: "Persecution_Evidence_Guide.pdf", path: "Resources/germany/Persecution_Evidence_Guide.pdf", sizeBytes: 185_000, downloadUrl: "https://www.yadvashem.org/", category: "Resources"),
                ResourceItem(name: "Anmeldung_Registration_Guide.pdf", path: "Arrival/germany/Anmeldung_Registration_Guide.pdf", sizeBytes: 150_000, downloadUrl: "https://service.berlin.de/dienstleistung/120335/", category: "Arrival"),
                ResourceItem(name: "Krankenversicherung_Health_Insurance_Guide.pdf", path: "Arrival/germany/Krankenversicherung_Health_Insurance_Guide.pdf", sizeBytes: 190_000, downloadUrl: "https://www.tk.de/en", category: "Arrival"),
                ResourceItem(name: "Rental_Contract_Template_DE.pdf", path: "Templates/germany/Rental_Contract_Template_DE.pdf", sizeBytes: 260_000, downloadUrl: nil, category: "Templates"),
            ]
        case "poland":
            return [
                ResourceItem(name: "Voivode_Citizenship_Confirmation_Application.pdf", path: "VisaForms/poland/Voivode_Citizenship_Confirmation_Application.pdf", sizeBytes: 230_000, downloadUrl: "https://www.gov.pl/web/usa-en/citizenship", category: "VisaForms"),
                ResourceItem(name: "Citizenship_Chain_Documentation_Checklist.pdf", path: "Resources/poland/Citizenship_Chain_Documentation_Checklist.pdf", sizeBytes: 175_000, downloadUrl: "https://www.gov.pl/", category: "Resources"),
                ResourceItem(name: "Apostille_and_Sworn_Translation_Guide_PL.pdf", path: "Resources/poland/Apostille_and_Sworn_Translation_Guide_PL.pdf", sizeBytes: 165_000, downloadUrl: "https://www.gov.pl/", category: "Resources"),
                ResourceItem(name: "PESEL_Number_Application_Guide.pdf", path: "Arrival/poland/PESEL_Number_Application_Guide.pdf", sizeBytes: 155_000, downloadUrl: "https://www.gov.pl/web/gov/uzyskaj-numer-pesel-dla-cudzoziemcow", category: "Arrival"),
                ResourceItem(name: "NFZ_Health_Registration_Guide.pdf", path: "Arrival/poland/NFZ_Health_Registration_Guide.pdf", sizeBytes: 180_000, downloadUrl: "https://www.nfz.gov.pl/", category: "Arrival"),
                ResourceItem(name: "Rental_Contract_Template_PL.pdf", path: "Templates/poland/Rental_Contract_Template_PL.pdf", sizeBytes: 250_000, downloadUrl: nil, category: "Templates"),
            ]
        case "argentina":
            return [
                ResourceItem(name: "Option_Declaration_Form_Argentine_Citizenship.pdf", path: "VisaForms/argentina/Option_Declaration_Form_Argentine_Citizenship.pdf", sizeBytes: 200_000, downloadUrl: "https://www.cancilleria.gob.ar/en/services/argentinians-abroad/argentine-citizenship", category: "VisaForms"),
                ResourceItem(name: "Consular_Document_Requirements_AR.pdf", path: "VisaForms/argentina/Consular_Document_Requirements_AR.pdf", sizeBytes: 175_000, downloadUrl: "https://www.cancilleria.gob.ar/", category: "VisaForms"),
                ResourceItem(name: "Apostille_and_Sworn_Translation_Guide_AR.pdf", path: "Resources/argentina/Apostille_and_Sworn_Translation_Guide_AR.pdf", sizeBytes: 165_000, downloadUrl: "https://www.traductores.org.ar/", category: "Resources"),
                ResourceItem(name: "DNI_Application_Guide.pdf", path: "Arrival/argentina/DNI_Application_Guide.pdf", sizeBytes: 155_000, downloadUrl: "https://www.argentina.gob.ar/interior/renaper", category: "Arrival"),
                ResourceItem(name: "CUIT_CUIL_Tax_ID_Guide.pdf", path: "Arrival/argentina/CUIT_CUIL_Tax_ID_Guide.pdf", sizeBytes: 145_000, downloadUrl: "https://www.afip.gob.ar/", category: "Arrival"),
                ResourceItem(name: "Rental_Contract_Template_AR.pdf", path: "Templates/argentina/Rental_Contract_Template_AR.pdf", sizeBytes: 235_000, downloadUrl: nil, category: "Templates"),
            ]
        case "hungary":
            return [
                ResourceItem(name: "Simplified_Naturalization_Application_Form.pdf", path: "VisaForms/hungary/Simplified_Naturalization_Application_Form.pdf", sizeBytes: 235_000, downloadUrl: "https://allampolgarsag.gov.hu/letoltheto-dokumentumok", category: "VisaForms"),
                ResourceItem(name: "Hungarian_Ancestor_Records_Guide.pdf", path: "Resources/hungary/Hungarian_Ancestor_Records_Guide.pdf", sizeBytes: 185_000, downloadUrl: "https://www.familysearch.org/en/search/collection/list?page=1&place=Hungary", category: "Resources"),
                ResourceItem(name: "OFFI_Translation_Process_Guide.pdf", path: "Resources/hungary/OFFI_Translation_Process_Guide.pdf", sizeBytes: 155_000, downloadUrl: "https://www.offi.hu/", category: "Resources"),
                ResourceItem(name: "Hungarian_Language_Interview_Prep.pdf", path: "Resources/hungary/Hungarian_Language_Interview_Prep.pdf", sizeBytes: 175_000, downloadUrl: "https://newyork.balassiintezet.hu/en/", category: "Resources"),
                ResourceItem(name: "Lakcimkartya_Address_Card_Guide.pdf", path: "Arrival/hungary/Lakcimkartya_Address_Card_Guide.pdf", sizeBytes: 145_000, downloadUrl: "https://nyilvantarto.hu/", category: "Arrival"),
                ResourceItem(name: "TAJ_Health_Insurance_Card_Guide.pdf", path: "Arrival/hungary/TAJ_Health_Insurance_Card_Guide.pdf", sizeBytes: 165_000, downloadUrl: "https://neak.gov.hu/", category: "Arrival"),
                ResourceItem(name: "Rental_Contract_Template_HU.pdf", path: "Templates/hungary/Rental_Contract_Template_HU.pdf", sizeBytes: 245_000, downloadUrl: nil, category: "Templates"),
            ]
        case "uk_ancestry":
            return [
                ResourceItem(name: "UK_Ancestry_Visa_Application_Guide.pdf", path: "VisaForms/uk_ancestry/UK_Ancestry_Visa_Application_Guide.pdf", sizeBytes: 245_000, downloadUrl: "https://www.gov.uk/ancestry-visa/apply", category: "VisaForms"),
                ResourceItem(name: "Ancestry_Visa_Document_Checklist.pdf", path: "VisaForms/uk_ancestry/Ancestry_Visa_Document_Checklist.pdf", sizeBytes: 190_000, downloadUrl: "https://www.gov.uk/ancestry-visa/documents-you-must-provide", category: "VisaForms"),
                ResourceItem(name: "ILR_Settlement_Application_Form_SET_M.pdf", path: "VisaForms/uk_ancestry/ILR_Settlement_Application_Form_SET_M.pdf", sizeBytes: 215_000, downloadUrl: "https://www.gov.uk/ancestry-visa/settle-in-the-uk", category: "VisaForms"),
                ResourceItem(name: "GRO_Birth_Certificate_Order_Guide.pdf", path: "Resources/uk_ancestry/GRO_Birth_Certificate_Order_Guide.pdf", sizeBytes: 175_000, downloadUrl: "https://www.gro.gov.uk/gro/content/certificates/", category: "Resources"),
                ResourceItem(name: "TB_Test_Country_List.pdf", path: "Resources/uk_ancestry/TB_Test_Country_List.pdf", sizeBytes: 145_000, downloadUrl: "https://www.gov.uk/tb-test-visa", category: "Resources"),
                ResourceItem(name: "National_Insurance_Number_Guide.pdf", path: "Arrival/uk_ancestry/National_Insurance_Number_Guide.pdf", sizeBytes: 155_000, downloadUrl: "https://www.gov.uk/apply-national-insurance-number", category: "Arrival"),
                ResourceItem(name: "NHS_GP_Registration_Guide.pdf", path: "Arrival/uk_ancestry/NHS_GP_Registration_Guide.pdf", sizeBytes: 165_000, downloadUrl: "https://www.nhs.uk/nhs-services/gps/how-to-register-with-a-gp-surgery/", category: "Arrival"),
                ResourceItem(name: "Rental_Contract_Template_UK.pdf", path: "Templates/uk_ancestry/Rental_Contract_Template_UK.pdf", sizeBytes: 260_000, downloadUrl: nil, category: "Templates"),
            ]
        default:
            return []
        }
    }
}
