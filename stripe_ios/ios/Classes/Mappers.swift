import Stripe

class Mappers {
    class func mapToPKContactField(field: String) -> PKContactField {
        switch field {
        case "emailAddress": return PKContactField.emailAddress
        case "name": return PKContactField.name
        case "phoneNumber": return PKContactField.phoneNumber
        case "phoneticName": return PKContactField.phoneticName
        case "postalAddress": return PKContactField.postalAddress
        default: return PKContactField.name
        }
    }
    
    class func mapToShippingMethodType(type: String?) -> PKPaymentSummaryItemType {
        if let type = type {
            switch type {
            case "pending": return PKPaymentSummaryItemType.pending
            case "final": return PKPaymentSummaryItemType.final
            default: return PKPaymentSummaryItemType.final
            }
        }
        return PKPaymentSummaryItemType.final
    }
    
    class func mapToShippingMethods(shippingMethods: NSArray?) -> [PKShippingMethod] {
        var shippingMethodsList: [PKShippingMethod] = []
        
        if let methods = shippingMethods as? [[String : Any]] {
            for method in methods {
                let label = method["label"] as? String ?? ""
                let amount = NSDecimalNumber(string: method["amount"] as? String ?? "")
                let identifier = method["identifier"] as! String
                let detail = method["detail"] as? String ?? ""
                let type = Mappers.mapToShippingMethodType(type: method["type"] as? String)
                let pm = PKShippingMethod.init(label: label, amount: amount, type: type)
                pm.identifier = identifier
                pm.detail = detail
                shippingMethodsList.append(pm)
            }
        }
        
        return shippingMethodsList
    }
    
    
    class func mapIntentStatus(status: STPPaymentIntentStatus?) -> String {
        if let status = status {
            switch status {
            case STPPaymentIntentStatus.succeeded: return "Succeeded"
            case STPPaymentIntentStatus.requiresPaymentMethod: return "RequiresPaymentMethod"
            case STPPaymentIntentStatus.requiresConfirmation: return "RequiresConfirmation"
            case STPPaymentIntentStatus.canceled: return "Canceled"
            case STPPaymentIntentStatus.processing: return "Processing"
            case STPPaymentIntentStatus.requiresAction: return "RequiresAction"
            case STPPaymentIntentStatus.requiresCapture: return "RequiresCapture"
            default: return "Unknown"
            }
        }
        return "Unknown"
    }
    
    class func mapPaymentMethodType(type: STPPaymentMethodType) -> String {
        switch type {
        case STPPaymentMethodType.card: return "Card"
        case STPPaymentMethodType.alipay: return "Alipay"
        case STPPaymentMethodType.grabPay: return "GrabPay"
        case STPPaymentMethodType.iDEAL: return "Ideal"
        case STPPaymentMethodType.FPX: return "Fpx"
        case STPPaymentMethodType.cardPresent: return "CardPresent"
        case STPPaymentMethodType.SEPADebit: return "SepaDebit"
        case STPPaymentMethodType.AUBECSDebit: return "AuBecsDebit"
        case STPPaymentMethodType.bacsDebit: return "BacsDebit"
        case STPPaymentMethodType.giropay: return "Giropay"
        case STPPaymentMethodType.przelewy24: return "P24"
        case STPPaymentMethodType.EPS: return "Eps"
        case STPPaymentMethodType.bancontact: return "Bancontact"
        case STPPaymentMethodType.OXXO: return "Oxxo"
        case STPPaymentMethodType.sofort: return "Sofort"
        case STPPaymentMethodType.UPI: return "Upi"
        case STPPaymentMethodType.unknown: return "Unknown"
        default: return "Unknown"
        }
    }
    
    class func mapCardParamsToPaymentMethodParams(params: NSDictionary, billingDetails: STPPaymentMethodBillingDetails?) -> STPPaymentMethodParams {
        let cardSourceParams = STPCardParams()
        cardSourceParams.number = params["number"] as? String
        cardSourceParams.cvc = params["cvc"]  as? String
        cardSourceParams.expMonth = params["expiryMonth"]  as! UInt
        cardSourceParams.expYear = params["expiryYear"]  as! UInt
        
        let cardParams = STPPaymentMethodCardParams(cardSourceParams: cardSourceParams)
        return STPPaymentMethodParams(card: cardParams, billingDetails: billingDetails, metadata: nil)
    }
    
    
    class func mapCaptureMethod(_ captureMethod: STPPaymentIntentCaptureMethod?) -> String {
        if let captureMethod = captureMethod {
            switch captureMethod {
            case STPPaymentIntentCaptureMethod.automatic: return "Automatic"
            case STPPaymentIntentCaptureMethod.manual: return "Manual"
            default: return "Unknown"
            }
        }
        return "Unknown"
    }
    
    class func mapConfirmationMethod(_ confirmationMethod: STPPaymentIntentConfirmationMethod?) -> String {
        if let confirmationMethod = confirmationMethod {
            switch confirmationMethod {
            case STPPaymentIntentConfirmationMethod.automatic: return "Automatic"
            case STPPaymentIntentConfirmationMethod.manual: return "Manual"
            default: return "Unknown"
            }
        }
        return "Unknown"
    }
    
    class func mapIntentShipping(_ shipping: STPPaymentIntentShippingDetails) -> NSDictionary {
        var addressDetails = NSDictionary()
        if let address = shipping.address {
            addressDetails = [
                "city": address.city ?? NSNull(),
                "country": address.country ?? NSNull(),
                "line1": address.line1 ?? NSNull(),
                "line2":address.line2 ?? NSNull(),
                "postalCode": address.postalCode ?? NSNull(),
            ]
        }
        let shippingDetails: NSDictionary = [
            "address": addressDetails,
            "name": shipping.name ?? NSNull(),
            "phone": shipping.phone ?? NSNull(),
            "trackingNumber": shipping.trackingNumber ?? NSNull(),
            "carrier": shipping.carrier ?? NSNull(),
        ]
        return shippingDetails
    }
    
    class func mapFromPaymentIntent (paymentIntent: STPPaymentIntent) -> NSDictionary {
        let intent: NSMutableDictionary = [
            "id": paymentIntent.stripeId,
            "currency": paymentIntent.currency,
            "status": Mappers.mapIntentStatus(status: paymentIntent.status),
            "description": paymentIntent.description,
            "clientSecret": paymentIntent.clientSecret,
            "receiptEmail": paymentIntent.receiptEmail ?? NSNull(),
            "livemode": paymentIntent.livemode,
            "paymentMethodId": paymentIntent.paymentMethodId ?? NSNull(),
            "captureMethod": mapCaptureMethod(paymentIntent.captureMethod),
            "confirmationMethod": mapConfirmationMethod(paymentIntent.confirmationMethod),
            "created": convertDateToUnixTimestamp(date: paymentIntent.created),
            "amount": paymentIntent.amount,
            "lastPaymentError": NSNull(),
            "shipping": NSNull(),
            "canceledAt": NSNull()
        ]
        
        if let lastPaymentError = paymentIntent.lastPaymentError {
            let paymentError: NSMutableDictionary = [
                "code": lastPaymentError.code ?? NSNull(),
                "message": lastPaymentError.message ?? NSNull(),
                "type": mapFromPaymentIntentLastPaymentErrorType(lastPaymentError.type)
            ]
            
            if let paymentMethod = paymentIntent.lastPaymentError?.paymentMethod {
                paymentError.setValue(mapFromPaymentMethod(paymentMethod), forKey: "paymentMethod")
            }
            intent.setValue(paymentError, forKey: "lastPaymentError")
        }
        
        if let shipping = paymentIntent.shipping {
            intent.setValue(mapIntentShipping(shipping), forKey: "shipping")
        }
        
        if let canceledAt = paymentIntent.canceledAt {
            intent.setValue(convertDateToUnixTimestamp(date: canceledAt), forKey: "canceledAt")
        }
        
        return intent;
    }
    
    class func mapFromPaymentIntentLastPaymentErrorType(_ errorType: STPPaymentIntentLastPaymentErrorType?) -> String {
        if let errorType = errorType {
            switch errorType {
            case STPPaymentIntentLastPaymentErrorType.apiConnection: return "ApiConnection"
            case STPPaymentIntentLastPaymentErrorType.api: return "Api"
            case STPPaymentIntentLastPaymentErrorType.authentication: return "Authentication"
            case STPPaymentIntentLastPaymentErrorType.card: return "Card"
            case STPPaymentIntentLastPaymentErrorType.idempotency: return "Idempotency"
            case STPPaymentIntentLastPaymentErrorType.invalidRequest: return "InvalidRequest"
            case STPPaymentIntentLastPaymentErrorType.rateLimit: return "RateLimit"
            case STPPaymentIntentLastPaymentErrorType.unknown: return "Unknown"
            default: return "Unknown"
            }
        }
        return "Unknown"
    }
    
    class func mapToBillingDetails(billingDetails: NSDictionary) -> STPPaymentMethodBillingDetails {
        let billing = STPPaymentMethodBillingDetails()
        billing.email = billingDetails["email"] as? String
        billing.phone = billingDetails["phone"] as? String
        billing.name = billingDetails["name"] as? String
        
        let billingAddres = STPPaymentMethodAddress()
        
        billingAddres.city = billingDetails["addressCity"] as? String
        billingAddres.postalCode = billingDetails["addressPostalCode"] as? String
        billingAddres.country = billingDetails["addressCountry"] as? String
        billingAddres.line1 = billingDetails["addressLine1"] as? String
        billingAddres.line2 = billingDetails["addressLine2"] as? String
        billingAddres.state = billingDetails["addressState"] as? String
        
        billing.address = billingAddres
        
        return billing
    }
    
    class func mapFromBillingDetails(billingDetails: STPPaymentMethodBillingDetails?) -> NSDictionary {
        let billing: NSDictionary = [
            "email": billingDetails?.email ?? NSNull(),
            "phone": billingDetails?.phone ?? NSNull(),
            "name": billingDetails?.name ?? NSNull(),
            "address": [
                "city": billingDetails?.address?.city,
                "postalCode": billingDetails?.address?.postalCode,
                "country": billingDetails?.address?.country,
                "line1": billingDetails?.address?.line1,
                "line2": billingDetails?.address?.line2,
                "state": billingDetails?.address?.state,
            ],
        ]
        
        return billing
    }
    
    class func mapCardBrand(_ brand: STPCardBrand?) -> String {
        if let brand = brand {
            switch brand {
            case STPCardBrand.visa: return "visa"
            case STPCardBrand.amex: return "americanExpress"
            case STPCardBrand.mastercard: return "masterCard"
            case STPCardBrand.discover: return "discover"
            case STPCardBrand.JCB: return "jCB"
            case STPCardBrand.dinersClub: return "dinersClub"
            case STPCardBrand.unionPay: return "unionPay"
            case STPCardBrand.unknown: return "unknown"
            default: return "unknown"
            }
        }
        return "unknown"
    }
    
    class func mapFromPaymentMethod(_ paymentMethod: STPPaymentMethod) -> NSDictionary {
        let card: NSDictionary = [
            "brand": Mappers.mapCardBrand(paymentMethod.card?.brand),
            "country": paymentMethod.card?.country ?? NSNull(),
            "expYear": paymentMethod.card?.expYear ?? NSNull(),
            "expMonth": paymentMethod.card?.expMonth ?? NSNull(),
            "fingerprint": paymentMethod.card?.fingerprint ?? NSNull(),
            "funding": paymentMethod.card?.funding ?? NSNull(),
            "last4": paymentMethod.card?.last4 ?? NSNull()
        ]
        let sepaDebit: NSDictionary = [
            "bankCode": paymentMethod.sepaDebit?.bankCode ?? NSNull(),
            "country": paymentMethod.sepaDebit?.country ?? NSNull(),
            "fingerprint": paymentMethod.sepaDebit?.fingerprint ?? NSNull(),
            "last4": paymentMethod.sepaDebit?.last4 ?? NSNull(),
        ]
        let bacsDebit: NSDictionary = [
            "fingerprint": paymentMethod.bacsDebit?.fingerprint ?? NSNull(),
            "last4": paymentMethod.bacsDebit?.last4 ?? NSNull(),
            "sortCode": paymentMethod.bacsDebit?.sortCode ?? NSNull()
        ]
        let auBECSDebit: NSDictionary = [
            "bsbNumber": paymentMethod.auBECSDebit?.bsbNumber ?? NSNull(),
            "fingerprint": paymentMethod.auBECSDebit?.fingerprint ?? NSNull(),
            "last4": paymentMethod.auBECSDebit?.last4 ?? NSNull()
        ]
        let method: NSDictionary = [
            "id": paymentMethod.stripeId,
            "type": Mappers.mapPaymentMethodType(type: paymentMethod.type),
            "livemode": paymentMethod.liveMode,
            "customerId": paymentMethod.customerId ?? NSNull(),
            "billingDetails": Mappers.mapFromBillingDetails(billingDetails: paymentMethod.billingDetails),
            "Card": card,
            "Ideal": [
                "bankIdentifierCode": paymentMethod.iDEAL?.bankIdentifierCode ?? "",
                "bankName": paymentMethod.iDEAL?.bankName ?? ""
            ],
            "Fpx": [
                "bank": paymentMethod.fpx?.bankIdentifierCode ?? "",
            ],
            "SepaDebit": sepaDebit,
            "BacsDebit": bacsDebit,
            "AuBecsDebit": auBECSDebit,
            "Sofort": [
                "country": paymentMethod.sofort?.country
            ],
            "Upi": [
                "vpa": paymentMethod.upi?.vpa
            ],
        ]
        return method
    }
    
    class func mapCardParams(params: NSDictionary) -> STPPaymentMethodCardParams {
        let cardSourceParams = STPCardParams()
        cardSourceParams.number = params["number"] as? String
        cardSourceParams.cvc = params["cvc"]  as? String
        cardSourceParams.expMonth = params["expiryMonth"]  as! UInt
        cardSourceParams.expYear = params["expiryYear"]  as! UInt
        return STPPaymentMethodCardParams(cardSourceParams: cardSourceParams)
    }
    
    class func mapIntentStatus(status: STPSetupIntentStatus?) -> String {
        if let status = status {
            switch status {
            case STPSetupIntentStatus.succeeded: return "Succeeded"
            case STPSetupIntentStatus.requiresPaymentMethod: return "RequiresPaymentMethod"
            case STPSetupIntentStatus.requiresConfirmation: return "RequiresConfirmation"
            case STPSetupIntentStatus.canceled: return "Canceled"
            case STPSetupIntentStatus.processing: return "Processing"
            case STPSetupIntentStatus.requiresAction: return "RequiresAction"
            case STPSetupIntentStatus.unknown: return "Unknown"
            default: return "Unknown"
            }
        }
        return "Unknown"
    }
    
    class func mapFromSetupIntentUsage(usage: STPSetupIntentUsage?) -> String {
        if let usage = usage {
            switch usage {
            case STPSetupIntentUsage.none: return "None"
            case STPSetupIntentUsage.offSession: return "OffSession"
            case STPSetupIntentUsage.onSession: return "OnSession"
            case STPSetupIntentUsage.unknown: return "Unknown"
            default: return "Unknown"
            }
        }
        return "Unknown"
    }
    
    class func mapToPaymentIntentFutureUsage(usage: String?) -> STPPaymentIntentSetupFutureUsage {
        if let usage = usage {
            switch usage {
            case "None": return STPPaymentIntentSetupFutureUsage.none
            case "OffSession": return STPPaymentIntentSetupFutureUsage.offSession
            case "OnSession": return STPPaymentIntentSetupFutureUsage.onSession
            case "Unknown": return STPPaymentIntentSetupFutureUsage.unknown
            default: return STPPaymentIntentSetupFutureUsage.unknown
            }
        }
        return STPPaymentIntentSetupFutureUsage.unknown
    }
    
    class func mapFromSetupIntent(setupIntent: STPSetupIntent) -> NSDictionary {
        let intent: NSMutableDictionary = [
            "id": setupIntent.stripeID,
            "clientSecret": setupIntent.clientSecret,
            "status": mapIntentStatus(status: setupIntent.status),
            "description": setupIntent.stripeDescription ?? NSNull(),
            "livemode": setupIntent.livemode,
            "paymentMethodTypes": NSArray(),
            "usage": mapFromSetupIntentUsage(usage: setupIntent.usage),
            "paymentMethodId": setupIntent.paymentMethodID ?? NSNull(),
            "created": NSNull(),
            "lastSetupError": NSNull()
        ]
        
        if let paymentMethodTypes = setupIntent.paymentMethodTypes {
            let types = paymentMethodTypes.map {
                mapPaymentMethodType(type: STPPaymentMethodType.init(rawValue: Int(truncating: $0))!)
            }
            intent.setValue(types, forKey: "paymentMethodTypes")
        }
        
        if let created = setupIntent.created {
            intent.setValue(convertDateToUnixTimestamp(date: created), forKey: "created")
        }
        
        if let lastSetupError = setupIntent.lastSetupError {
            let setupError = [
                "code": lastSetupError.code,
                "message": lastSetupError.description
            ]
            intent.setValue(setupError, forKey: "lastSetupError")
        }
        
        
        return intent
    }
    
    @available(iOS 13.0, *)
        class func mapToUserInterfaceStyle(_ style: String) -> PaymentSheet.UserInterfaceStyle {
            switch style {
            case "alwaysDark": return PaymentSheet.UserInterfaceStyle.alwaysDark
            case "alwaysLight": return PaymentSheet.UserInterfaceStyle.alwaysLight
            default: return PaymentSheet.UserInterfaceStyle.automatic
            }
        }
    
    class func mapUICustomization(_ params: NSDictionary) -> STPThreeDSUICustomization {
        let uiCustomization = STPThreeDSUICustomization()
        if let labelSettings = params["label"] as? Dictionary<String, Any?> {
            if let headingTextColor = labelSettings["headingTextColor"] as? String {
                uiCustomization.labelCustomization.headingTextColor = UIColor(hexString: headingTextColor)
            }
            if let textColor = labelSettings["textColor"] as? String {
                uiCustomization.labelCustomization.textColor = UIColor(hexString: textColor)
            }
            if let headingFontSize = labelSettings["headingFontSize"] as? Int {
                uiCustomization.labelCustomization.headingFont = UIFont.systemFont(ofSize: CGFloat(headingFontSize))
            }
            if let textFontSize = labelSettings["textFontSize"] as? Int {
                uiCustomization.labelCustomization.font = UIFont.systemFont(ofSize: CGFloat(textFontSize))
            }
        }
        
        if let navigationBarSettings = params["navigationBar"] as? Dictionary<String, Any?> {
            if let barTintColor = navigationBarSettings["barTintColor"] as? String {
                uiCustomization.navigationBarCustomization.barTintColor = UIColor(hexString: barTintColor)
            }
            if let barStyle = navigationBarSettings["barStyle"] as? Int {
                uiCustomization.navigationBarCustomization.barStyle = UIBarStyle(rawValue: barStyle) ?? .default
            }
            if let headerText = navigationBarSettings["headerText"] as? String {
                uiCustomization.navigationBarCustomization.headerText = headerText
            }
            if let buttonText = navigationBarSettings["buttonText"] as? String {
                uiCustomization.navigationBarCustomization.buttonText = buttonText
            }
            if let textFontSize = navigationBarSettings["textFontSize"] as? Int {
                uiCustomization.navigationBarCustomization.font = UIFont.systemFont(ofSize: CGFloat(textFontSize))
            }
            if let textColor = navigationBarSettings["textColor"] as? String {
                uiCustomization.navigationBarCustomization.textColor = UIColor(hexString: textColor)
            }
            if let translucent = navigationBarSettings["translucent"] as? Bool {
                uiCustomization.navigationBarCustomization.translucent = translucent
            }
        }
        
        if let textFieldSettings = params["textField"] as? Dictionary<String, Any?> {
            if let borderColor = textFieldSettings["borderColor"] as? String {
                uiCustomization.textFieldCustomization.borderColor = UIColor(hexString: borderColor)
            }
            if let borderWidth = textFieldSettings["borderWidth"] as? Int {
                uiCustomization.textFieldCustomization.borderWidth = CGFloat(borderWidth)
            }
            if let cornerRadius = textFieldSettings["cornerRadius"] as? Int {
                uiCustomization.textFieldCustomization.cornerRadius = CGFloat(cornerRadius)
            }
            if let textColor = textFieldSettings["textColor"] as? String {
                uiCustomization.textFieldCustomization.textColor = UIColor(hexString: textColor)
            }
            if let textFontSize = textFieldSettings["textFontSize"] as? Int {
                uiCustomization.textFieldCustomization.font = UIFont.systemFont(ofSize: CGFloat(textFontSize))
            }
        }
        
        if let footerSettings = params["footer"] as? Dictionary<String, Any?> {
            if let backgroundColor = footerSettings["backgroundColor"] as? String {
                uiCustomization.footerCustomization.backgroundColor = UIColor(hexString: backgroundColor)
            }
            if let chevronColor = footerSettings["chevronColor"] as? String {
                uiCustomization.footerCustomization.chevronColor = UIColor(hexString: chevronColor)
            }
            if let headingTextColor = footerSettings["headingTextColor"] as? String {
                uiCustomization.footerCustomization.headingTextColor = UIColor(hexString: headingTextColor)
            }
            if let textColor = footerSettings["textColor"] as? String {
                uiCustomization.footerCustomization.textColor = UIColor(hexString: textColor)
            }
        }
        
        if let submitButtonSettings = params["submitButton"] as? Dictionary<String, Any?> {
            let buttonCustomization = uiCustomization.buttonCustomization(for: STPThreeDSCustomizationButtonType.submit)
            
            if let backgroundColor = submitButtonSettings["backgroundColor"] as? String {
                buttonCustomization.backgroundColor = UIColor(hexString: backgroundColor)
            }
            if let cornerRadius = submitButtonSettings["cornerRadius"] as? Int {
                buttonCustomization.cornerRadius = CGFloat(cornerRadius)
            }
            if let textFontSize = submitButtonSettings["textFontSize"] as? Int {
                buttonCustomization.font = UIFont.systemFont(ofSize: CGFloat(textFontSize))
            }
            if let textColor = submitButtonSettings["textColor"] as? String {
                buttonCustomization.textColor = UIColor(hexString: textColor)
            }
        }
        
        if let backgroundColor = params["backgroundColor"] as? String {
            uiCustomization.backgroundColor = UIColor(hexString: backgroundColor)
        }
        
        return uiCustomization
    }
    
    class func convertDateToUnixTimestamp(date: Date) -> UInt64 {
        return UInt64(date.timeIntervalSince1970 * 1000.0)
    }
}