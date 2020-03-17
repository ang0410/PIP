//
//  NAChangeLanguage.swift
//  Pubu
//
//  Created by an chieh huang on 2019/6/3.
//  Copyright © 2019 Nuazure. All rights reserved.
//

import Foundation

@objc class RGChangeLanguage: NSObject {
    @objc static let shareInstance = RGChangeLanguage()
    let userDefaults = UserDefaults.standard
    var bundle: Bundle?
    let userLanguage = "UserLanguage"
    let appleLanguages = "AppleLanguages"
    @objc var currentUserLanguage: String {
        return userDefaults.value(forKey: userLanguage) as? String ?? ""
    }
    
    @objc func initUserLanguage() {
        var languageString = userDefaults.value(forKey: userLanguage) as? String ?? ""

        languageString = defaultUserLanguage(language: languageString)
        languageString = languageString.replacingOccurrences(of: "-CN", with: "")
        languageString = languageString.replacingOccurrences(of: "-US", with: "")
        
        let bundlePath = setBundlePath(language: languageString)
        bundle = Bundle(path: bundlePath)
        
        setLanguage(language: languageString, needResetMainPage: false)
    }
    
    private func defaultUserLanguage(language: String) -> String {
        guard language == "" else {return language}
        guard let currentLang = Bundle.main.preferredLocalizations.first else {return ""}
        
        userDefaults.set(currentLang, forKey: userLanguage)
        userDefaults.synchronize()
        return currentLang
    }
    
    func resetLanguage() {
        guard let currentLang = Bundle.main.preferredLocalizations.first else {return}
        setLanguage(language: currentLang, needResetMainPage: false)
    }
    
    private func setBundlePath(language: String) -> String {
        
        if let path = Bundle.main.path(forResource: language, ofType: "lproj") {
            return path
        }
        
        let path = Bundle.main.path(forResource: "zh-Hant", ofType: "lproj") ?? ""
        return path
    }
    
    func updateLanguage(language: String) {
        userDefaults.set(language, forKey: userLanguage)
        userDefaults.synchronize()
        
        guard let path = Bundle.main.path(forResource: language, ofType: "lproj") else {return}
        bundle = Bundle(path: path)
        
        //objective c localized 設定
        object_setClass(Bundle.main, ExBundle.classForCoder())
        objc_setAssociatedObject(Bundle.main, &kBundleKey, bundle, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
    
    func setLanguage(language: String, needResetMainPage: Bool = true) {
        updateLanguage(language: language)

//        PubuHWManager.sharedInstance()?.updateUserAgentLocale(language+"_US" )
//        NABaseCatalogManager.sharedInstance().updateCatelogDictToCache("retail", dict: NSDictionary())
//        NABaseCatalogManager.sharedInstance().updateCatelogDictToCache("channel-1", dict: NSDictionary())
//        NADigestArticleManager.sharedInstance().getDigestCategoryApiCall(nextTask: {(category) in})
//
//        CURRENT_LANGUAGE = language as NSString
//        //http://issue.nuazure.com/issues/81768
//        //[本地推薦]切換語言後，推薦給你的分類顯示英文
//        NACatalogTool.getReferenceCatalog { (_) in}
//        //inform flutter to change locale
//        NAFlutterEngineManager.shared().changeLocale()
        
        guard needResetMainPage else {return}
        resetMainPage()
    }
    
    private func resetMainPage() {

    }
}

//swift 使用
func NSLocalizedString(_ lang: String, comment: String = "") -> String {
    let bundle = RGChangeLanguage.shareInstance.bundle
    guard let language = bundle?.localizedString(forKey: lang, value: nil, table: nil) else {return lang}
    return localizedStringFilter(lang: language)
}

//objective c 使用
var kBundleKey = "kBundleKey"
class ExBundle: Bundle {
    override func localizedString(forKey key: String, value: String?, table tableName: String?) -> String {
        if let bundle = objc_getAssociatedObject(self, &kBundleKey) as? Bundle {
            let language = bundle.localizedString(forKey: key, value: value, table: tableName)
            return localizedStringFilter(lang: language)
        }
        
        let language = super.localizedString(forKey: key, value: value, table: tableName)
        return localizedStringFilter(lang: language)
    }
}

private func localizedStringFilter(lang: String) -> String {
    var filterLang = lang
    filterLang = filterLang.replacingOccurrences(of: "％", with: "%")
    filterLang = filterLang.replacingOccurrences(of: "%1$s", with: "%@")
    filterLang = filterLang.replacingOccurrences(of: "%2$s", with: "%@")
    filterLang = filterLang.replacingOccurrences(of: "%3$s", with: "%@")
    filterLang = filterLang.replacingOccurrences(of: "%4$s", with: "%@")
    filterLang = filterLang.replacingOccurrences(of: "%%s", with: "%@")
    filterLang = filterLang.replacingOccurrences(of: "%s", with: "%@")
    filterLang = filterLang.replacingOccurrences(of: "\\n", with: "\n")
    return filterLang
}
