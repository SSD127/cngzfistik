# Uygulama Planı: Fıstık Komisyon Platformu

## Genel Bakış

Flutter (web + mobil) + Firebase Spark Plan üzerine inşa edilen bu platform; emanet fıstık takibi, satış/alım işlemleri, kasa yönetimi, depo takibi ve raporlamayı kapsar. Görevler katmanlı mimariye (Repository → ViewModel → UI) göre sıralanmış olup her adım bir öncekinin üzerine inşa edilir.

## Görevler

- [x] 1. Proje iskeleti ve temel yapılandırma
  - `flutter create` ile proje oluştur, `pubspec.yaml`'a bağımlılıkları ekle: `firebase_core`, `firebase_auth`, `cloud_firestore`, `firebase_storage`, `flutter_riverpod`, `riverpod_annotation`, `go_router`, `pdf`, `printing`
  - `lib/` altında tasarım dokümanındaki klasör yapısını oluştur: `app/`, `core/`, `features/`, `services/`
  - `firebase_options.dart` dosyasını `flutterfire configure` ile üret
  - `main.dart`'ta Firebase başlatma ve Riverpod `ProviderScope` sarmalayıcısını kur
  - `core/constants/firestore_paths.dart` içinde tüm koleksiyon yolu sabitlerini tanımla
  - _Gereksinimler: 13.1_

- [ ] 2. Kimlik doğrulama ve yetkilendirme
  - [ ] 2.1 `AuthRepository` sınıfını yaz
    - `signInWithEmailAndPassword`, `signOut`, `authStateChanges` stream metodlarını implement et
    - `users/{uid}` dokümanından kullanıcı rolünü oku
    - _Gereksinimler: 1.1, 1.4, 25.1_

  - [ ] 2.2 `AuthNotifier` Riverpod provider'ını yaz
    - Giriş, çıkış ve rol yönetimi iş mantığını implement et
    - _Gereksinimler: 1.2, 1.3_

  - [ ] 2.3 `LoginScreen` widget'ını yaz
    - E-posta/şifre form alanları, hata mesajı gösterimi ve yükleme durumu
    - _Gereksinimler: 1.1, 1.3_

  - [ ] 2.4 GoRouter yapılandırmasını yaz (`app/router.dart`)
    - Tüm route tanımlarını ekle: `/login`, `/admin/**`, `/c/:token`
    - `authStateChanges` dinleyerek oturum durumuna göre yönlendirme guard'ı implement et
    - `/c/:token` rotası için kimlik doğrulamasız erişime izin ver
    - _Gereksinimler: 1.2, 1.4, 1.6, 1.7_

  - [ ]* 2.5 `AuthRepository` için birim testleri yaz
    - Mock Firebase Auth ile giriş başarı/hata senaryolarını test et
    - _Gereksinimler: 1.1, 1.3_

- [ ] 3. Firestore güvenlik kuralları
  - [ ] 3.1 `firestore.rules` dosyasını yaz
    - `isOwner()`, `isEmployee()`, `isReadonly()` yardımcı fonksiyonlarını tanımla
    - Her koleksiyon için tasarım dokümanındaki kural stratejisini uygula
    - `audit_logs` için istemci yazma erişimini engelle
    - _Gereksinimler: 13.5, 25.2, 25.3, 26.1, 26.3_

  - [ ]* 3.2 Güvenlik kuralları için birim testleri yaz
    - Firebase Emulator Suite ile admin, employee, readonly ve anonim erişim senaryolarını test et
    - _Gereksinimler: 13.5, 26.1_

- [ ] 4. Müşteri yönetimi
  - [ ] 4.1 `CustomerModel` veri modelini ve `CustomerRepository`'yi yaz
    - Firestore CRUD işlemlerini implement et
    - `token_generator.dart`'ta 128-bit UUID v4 token üretimini implement et
    - Soft delete mantığını (`isDeleted` alanı) implement et
    - _Gereksinimler: 2.1, 2.2, 2.3, 18.1, 20.1, 20.2_

  - [ ] 4.2 Müşteri silme doğrulama mantığını implement et
    - Silme öncesi aktif kasa bakiyesi ve emanet fıstık kontrolü yap
    - _Gereksinimler: 2.4, 2.5_

  - [ ] 4.3 Müşteri link yenileme işlevini implement et
    - Yeni token üret, eski tokeni geçersiz kıl
    - _Gereksinimler: 18.2, 18.3_

  - [ ] 4.4 `CustomerListScreen` ve `CustomerDetailScreen` widget'larını yaz
    - Liste ekranında toplam emanet fıstık ve kasa bakiyesini göster
    - Müşteri_Sayfası URL'sini kopyalama/paylaşma butonunu ekle
    - _Gereksinimler: 2.6, 2.7_

  - [ ]* 4.5 Token benzersizliği için özellik tabanlı test yaz
    - **Özellik 1: Token Benzersizliği ve Kalitesi**
    - **Doğrular: Gereksinim 1.5, 18.1**

  - [ ]* 4.6 Aktif bakiyeli müşteri silme engeli için özellik tabanlı test yaz
    - **Özellik 3: Aktif Bakiyeli Müşteri Silme Engeli**
    - **Doğrular: Gereksinim 2.4, 2.5**

- [ ] 5. Fıstık cinsi ve fiyat yönetimi
  - [ ] 5.1 `PistachioTypeModel` ve `PriceHistoryModel` veri modellerini yaz
    - `PistachioTypeRepository`'yi implement et: CRUD + fiyat geçmişi kaydetme
    - En güncel kur değerini döndüren sorguyu implement et
    - _Gereksinimler: 3.1, 3.2, 3.3, 3.4, 3.5, 3.6_

  - [ ] 5.2 `PistachioTypesScreen` widget'ını yaz
    - Fıstık cinsi listesi, yeni cins ekleme formu ve günlük kur giriş alanı
    - Kur girilmemişse uyarı gösterimi
    - _Gereksinimler: 3.3, 3.7_

  - [ ]* 5.3 En güncel kur seçimi için özellik tabanlı test yaz
    - **Özellik 4: En Güncel Kur Seçimi**
    - **Doğrular: Gereksinim 3.3, 3.5**

- [ ] 6. Dinamik fıstık özellik şablonları
  - [ ] 6.1 `PistachioAttributeModel` veri modelini ve `PistachioAttributeRepository`'yi yaz
    - `select` ve `numeric` veri tiplerini destekle
    - Şablon silme sonrası mevcut parti verilerini koruma mantığını implement et
    - _Gereksinimler: 30.1, 30.2, 30.5, 30.9_

  - [ ] 6.2 `PistachioAttributesScreen` widget'ını yaz
    - Özellik şablonu oluşturma/düzenleme formu; seçimli liste için seçenek yönetimi
    - Fiyat çarpanı ayarı
    - _Gereksinimler: 30.1, 30.2, 30.6_

  - [ ]* 6.3 Özellik değerleri dayanıklılığı için özellik tabanlı test yaz
    - **Özellik 14: Fıstık Partisi Özellik Değerleri Dayanıklılığı**
    - **Doğrular: Gereksinim 30.4, 30.9**

- [ ] 7. Depo yönetimi
  - [ ] 7.1 `WarehouseModel` ve `WarehouseRepository`'yi yaz
    - CRUD işlemleri, aktif/pasif durum yönetimi
    - `warehouse_summaries` denormalize özet güncelleme mantığını implement et
    - _Gereksinimler: 4.1, 4.2, 4.3, 4.4_

  - [ ] 7.2 `WarehousesScreen` widget'ını yaz
    - Depo listesi, fıstık cinsi bazında stok özeti
    - _Gereksinimler: 4.5_

- [ ] 8. Checkpoint — Temel altyapı doğrulaması
  - Tüm testlerin geçtiğini doğrula, Firebase Emulator ile auth ve Firestore bağlantısını test et. Sorularınız varsa kullanıcıya danışın.

- [ ] 9. Emanet fıstık takibi
  - [ ] 9.1 `InventoryDepositModel`, `StockMovementModel` veri modellerini ve `InventoryRepository`'yi yaz
    - Emanet giriş kaydı, düzeltme logu ve soft delete implement et
    - Dinamik özellik değerlerini (`attributes` map) kaydetme mantığını implement et
    - _Gereksinimler: 5.1, 5.4, 5.5, 30.3, 30.4_

  - [ ] 9.2 Emanet fıstık girişi transaction'ını implement et
    - `runTransaction` içinde: müşteri özet bakiyesini artır, depo stokunu artır, `stock_movements` kaydı oluştur
    - _Gereksinimler: 5.2, 14.1, 14.3, 15.1, 15.2_

  - [ ] 9.3 `InventoryDepositScreen` widget'ını yaz
    - Müşteri, fıstık cinsi, miktar, depo seçimi; dinamik özellik alanları (dropdown/sayı)
    - _Gereksinimler: 5.1, 30.3_

  - [ ]* 9.4 Emanet girişi tutarlılığı için özellik tabanlı test yaz
    - **Özellik 5: Emanet Girişi Tutarlılığı**
    - **Doğrular: Gereksinim 5.1, 5.2**

- [ ] 10. Satış işlemleri
  - [ ] 10.1 `SaleModel` veri modelini ve `SalesRepository`'yi yaz
    - `transaction_number.dart`'ta benzersiz işlem numarası üretimini implement et
    - _Gereksinimler: 6.5, 27.1, 27.2, 27.3_

  - [ ] 10.2 Fiyat hesaplama fonksiyonunu yaz
    - `totalAmount = quantityKg × pricePerKgAtTime × innerGramRatioAtTime` formülünü saf fonksiyon olarak implement et
    - _Gereksinimler: 6.2, 17.1_

  - [ ] 10.3 Satış transaction'ını implement et
    - `runTransaction` içinde: emanet bakiyesini düşür, depo stokunu düşür, kasa bakiyesini artır, `sales`/`cash_movements`/`stock_movements` kayıtlarını oluştur, `monthly_summaries`'i güncelle
    - Yetersiz stok kontrolünü implement et
    - _Gereksinimler: 6.3, 6.4, 14.1, 14.3, 22.3_

  - [ ] 10.4 `NewSaleScreen` widget'ını yaz
    - Müşteri, fıstık cinsi, miktar, depo seçimi; anlık tutar hesaplama önizlemesi; kur uyarısı
    - _Gereksinimler: 6.1, 3.7_

  - [ ]* 10.5 Fiyat hesaplama doğruluğu için özellik tabanlı test yaz
    - **Özellik 6: Fiyat Hesaplama Doğruluğu**
    - **Doğrular: Gereksinim 6.2**

  - [ ]* 10.6 Satış transaction tutarlılığı için özellik tabanlı test yaz
    - **Özellik 8: Satış Transaction Tutarlılığı**
    - **Doğrular: Gereksinim 6.4**

  - [ ]* 10.7 Bakiye yetersizliğinde işlem reddi için özellik tabanlı test yaz
    - **Özellik 7: Bakiye Yetersizliğinde İşlem Reddi**
    - **Doğrular: Gereksinim 6.3, 7.2, 7.3, 8.5, 29.4**

- [ ] 11. Fıstık alım işlemleri
  - [ ] 11.1 `PurchaseModel` veri modelini ve `PurchasesRepository`'yi yaz
    - `source` (warehouse/external) ve `paymentMethod` (cash_balance/cash) alanlarını implement et
    - _Gereksinimler: 7.1, 7.6_

  - [ ] 11.2 Alım transaction'ını implement et
    - `runTransaction` içinde: kasa bakiyesi kontrolü, depo stoku güncelleme, kasa hareketi oluşturma
    - "Dışarıdan" alım için gider kaydı oluşturma
    - _Gereksinimler: 7.2, 7.3, 7.4, 7.5, 14.1_

  - [ ] 11.3 `NewPurchaseScreen` widget'ını yaz
    - Kaynak ve ödeme yöntemi seçimi; yetersiz bakiye uyarısı
    - _Gereksinimler: 7.1, 7.3_

- [ ] 12. Kasa ve para yönetimi
  - [ ] 12.1 `CashMovementModel` veri modelini ve `CashRepository`'yi yaz
    - Para girişi ve çıkışı transaction'larını implement et
    - Negatif bakiye (borç) desteğini implement et
    - _Gereksinimler: 8.1, 8.2, 8.3, 8.4, 16.1, 16.2_

  - [ ] 12.2 `CashDepositScreen` ve `CashWithdrawalScreen` widget'larını yaz
    - Yetersiz bakiye kontrolü ve hata mesajı
    - Tarih aralığı filtreli kasa hareketi listesi
    - _Gereksinimler: 8.5, 8.6, 8.7, 8.8_

- [ ] 13. Fiş oluşturma ve yazdırma
  - [ ] 13.1 `PdfService` sınıfını yaz
    - `pdf` paketi ile fiş PDF'i oluştur: işlem numarası, tarih/saat, müşteri adı, işlem türü, fıstık cinsi, miktar, kur, toplam tutar, güncel kasa bakiyesi
    - `printing` paketi ile yazdırma diyaloğunu aç
    - PDF indirme fonksiyonunu implement et
    - _Gereksinimler: 9.1, 9.2, 9.3, 9.4_

  - [ ] 13.2 `ReceiptModel` veri modelini ve `ReceiptsRepository`'yi yaz
    - Her işlem sonrası otomatik fiş kaydı oluşturma mantığını implement et
    - Geçmiş fişlere erişim sorgusunu implement et
    - _Gereksinimler: 9.1, 9.5, 27.1, 27.2_

  - [ ] 13.3 Fiş görüntüleme ve yazdırma UI bileşenini yaz
    - İşlem detay ekranlarına "Fişi Yazdır" ve "PDF İndir" butonlarını ekle
    - _Gereksinimler: 6.6, 9.3, 9.4_

- [ ] 14. Checkpoint — İşlem akışları doğrulaması
  - Satış, alım ve kasa işlemlerinin uçtan uca çalıştığını Firebase Emulator ile doğrula. Sorularınız varsa kullanıcıya danışın.

- [ ] 15. Gider yönetimi
  - [ ] 15.1 `ExpenseModel` veri modelini ve `ExpensesRepository`'yi yaz
    - CRUD işlemleri ve soft delete implement et
    - Tarih aralığı + kategori filtreli sorguyu implement et
    - _Gereksinimler: 10.1, 10.2, 10.6, 10.7, 20.1_

  - [ ] 15.2 Belge yükleme işlevini implement et
    - Firebase Storage'a yükleme, 5 MB istemci tarafı boyut kontrolü
    - `documentUrl` ve `documentPath` alanlarını gider kaydıyla ilişkilendir
    - _Gereksinimler: 10.3, 10.4, 10.5, 13.3, 13.4_

  - [ ] 15.3 `ExpensesScreen` widget'ını yaz
    - Gider listesi, yeni gider formu, belge yükleme/görüntüleme
    - _Gereksinimler: 10.1, 10.5_

  - [ ]* 15.4 Dosya boyutu sınırı için özellik tabanlı test yaz
    - **Özellik 9: Dosya Boyutu Sınırı**
    - **Doğrular: Gereksinim 13.3, 13.4**

- [ ] 16. Depo transferi
  - [ ] 16.1 Depo transferi transaction'ını implement et
    - `runTransaction` içinde: kaynak depoda stok düşür, hedef depoda stok artır, `stock_movements`'a `transfer_out`/`transfer_in` kayıtları ekle
    - Negatif stok kontrolünü implement et
    - _Gereksinimler: 4.6, 14.3, 15.4_

  - [ ] 16.2 `WarehouseTransferScreen` widget'ını yaz
    - Kaynak/hedef depo ve miktar seçimi
    - _Gereksinimler: 4.6_

  - [ ]* 16.3 Negatif stok engeli için özellik tabanlı test yaz
    - **Özellik 10: Negatif Stok Engeli**
    - **Doğrular: Gereksinim 15.4**

- [ ] 17. İşlem iptal ve ters kayıt sistemi
  - [ ] 17.1 İptal transaction'ını implement et
    - Satış, alım ve kasa hareketleri için ters kayıt (`reversal`) oluştur
    - Etkilenen tüm bakiyeleri (emanet fıstık, depo stoku, kasa) geri al
    - `isCancelled: true` ve `cancellationReason` alanlarını güncelle
    - _Gereksinimler: 24.1, 24.2, 24.3, 24.4_

  - [ ]* 17.2 İptal ters kayıt round-trip için özellik tabanlı test yaz
    - **Özellik 13: İptal Ters Kayıt Round-Trip**
    - **Doğrular: Gereksinim 24.1, 24.2**

- [ ] 18. Kasa emaneti modülü (döviz/altın)
  - [ ] 18.1 `VaultItemModel`, `VaultMovementModel` veri modellerini ve `VaultRepository`'yi yaz
    - Cins bazında bakiye takibi (USD, EUR, TL, altın gram, diğer)
    - Emanet girişi ve iadesi transaction'larını implement et
    - _Gereksinimler: 29.1, 29.2, 29.3, 29.4, 29.8_

  - [ ] 18.2 `VaultScreen` widget'ını yaz
    - Emanet sahibi bazında bakiye özeti, hareket listesi, giriş/çıkış formları
    - _Gereksinimler: 29.6, 29.7_

  - [ ] 18.3 Kasa emaneti fişi oluşturmayı `PdfService`'e ekle
    - _Gereksinimler: 29.5_

- [ ] 19. Audit log sistemi
  - [ ] 19.1 `AuditLogService` sınıfını yaz
    - Kritik işlemler (silme, iptal, düzeltme) sonrası `audit_logs` koleksiyonuna kayıt ekle
    - Eski değer / yeni değer karşılaştırmasını implement et
    - _Gereksinimler: 19.1, 19.2, 19.3_

  - [ ] 19.2 Kritik işlem akışlarına audit log çağrılarını entegre et
    - Müşteri silme, işlem iptali, emanet düzeltme işlemlerinde `AuditLogService`'i çağır
    - _Gereksinimler: 19.1_

- [ ] 20. Raporlama
  - [ ] 20.1 `MonthlySummaryModel` veri modelini ve `ReportsRepository`'yi yaz
    - `monthly_summaries` koleksiyonundan aylık müşteri raporu sorgusunu implement et
    - Kasa hareketlilik raporu sorgusunu implement et
    - Gider raporu (kategori bazında gruplandırma) sorgusunu implement et
    - Depo stok raporu sorgusunu implement et
    - _Gereksinimler: 11.1, 11.2, 11.3, 11.4, 22.1, 22.2_

  - [ ] 20.2 Rapor ekranlarını yaz
    - `MonthlyReportScreen`, `CashFlowReportScreen`, `ExpenseReportScreen`, `StockReportScreen`
    - Tarih aralığı filtresi ve borç durumu gösterimi
    - _Gereksinimler: 11.1, 11.2, 11.3, 11.4, 16.3_

  - [ ] 20.3 Rapor PDF dışa aktarımını `PdfService`'e ekle
    - _Gereksinimler: 11.5_

- [ ] 21. Müşteri sayfası (salt-okunur görünüm)
  - [ ] 21.1 Token tabanlı müşteri veri sorgusunu implement et
    - `pageToken` alanına göre Firestore sorgusu yap, kimlik doğrulamasız erişimi destekle
    - Geçersiz token için 404 yönlendirmesini implement et
    - _Gereksinimler: 1.5, 1.6, 1.7, 1.8_

  - [ ] 21.2 `CustomerPageScreen` widget'ını yaz
    - Fıstık cinsi bazında emanet bakiyesi, satılan toplam fıstık, kasa bakiyesi
    - Son işlem hareketleri listesi (kronolojik)
    - Fıstık partisi özellik değerlerini tablo halinde göster
    - "Aktif işlem bulunmamaktadır" boş durum mesajı
    - Mobil uyumlu responsive tasarım
    - _Gereksinimler: 12.1, 12.2, 12.3, 12.4, 12.5, 30.7, 30.8_

  - [ ]* 21.3 Token tabanlı erişim izolasyonu için özellik tabanlı test yaz
    - **Özellik 2: Token Tabanlı Erişim İzolasyonu**
    - **Doğrular: Gereksinim 1.6**

- [ ] 22. Veri yedekleme
  - [ ] 22.1 `BackupService` sınıfını yaz
    - Müşteri, işlem ve kasa verilerini JSON formatında dışa aktarma fonksiyonunu implement et
    - CSV dışa aktarım seçeneğini implement et
    - _Gereksinimler: 28.1, 28.2, 28.3_

  - [ ] 22.2 Yedekleme UI bileşenini `SettingsScreen`'e ekle
    - _Gereksinimler: 28.2_

- [ ] 23. Sayfalama ve performans optimizasyonu
  - [ ] 23.1 Listeleme ekranlarına Firestore cursor tabanlı sayfalama ekle
    - Müşteri listesi, kasa hareketleri, gider listesi, stok hareketleri ekranlarını güncelle
    - _Gereksinimler: 21.1, 21.2_

  - [ ] 23.2 Riverpod provider'larında `keepAlive` ve önbellekleme stratejisini uygula
    - Gereksiz Firestore okumalarını azaltmak için provider yeniden kullanımını optimize et
    - _Gereksinimler: 13.2, 21.4, 22.1_

- [ ] 24. Çevrimdışı destek ve senkronizasyon bildirimi
  - [ ] 24.1 Firestore offline persistence ayarını `main.dart`'ta yapılandır
    - `persistenceEnabled: true` ve `cacheSizeBytes: CACHE_SIZE_UNLIMITED` ayarlarını ekle
    - _Gereksinimler: 23.1_

  - [ ] 24.2 Çevrimiçi/çevrimdışı durum göstergesini implement et
    - `snapshotsInSync()` stream'ini dinleyerek UI'da bağlantı durumu bildirimi göster
    - _Gereksinimler: 23.3_

- [ ] 25. Soft delete round-trip doğrulaması
  - [ ]* 25.1 Soft delete round-trip için özellik tabanlı test yaz
    - **Özellik 12: Soft Delete Round-Trip**
    - **Doğrular: Gereksinim 20.1, 20.2, 20.4**

- [ ] 26. Kur sabitleme doğrulaması
  - [ ]* 26.1 Kur sabitleme için özellik tabanlı test yaz
    - **Özellik 11: Kur Sabitleme**
    - **Doğrular: Gereksinim 17.1, 17.2**

- [ ] 27. Admin dashboard
  - [ ] 27.1 `DashboardScreen` widget'ını yaz
    - Toplam müşteri sayısı, toplam emanet fıstık, toplam kasa bakiyesi özet kartları
    - Borçlu müşteri listesi
    - Son işlemler akışı
    - _Gereksinimler: 16.3_

- [ ] 28. Final checkpoint — Uçtan uca doğrulama
  - Tüm testlerin geçtiğini doğrula. Firebase Emulator ile tam iş akışlarını (satış → fiş → iptal → ters kayıt) test et. Sorularınız varsa kullanıcıya danışın.

## Notlar

- `*` ile işaretli görevler isteğe bağlıdır; MVP için atlanabilir
- Her görev ilgili gereksinimlere referans verir
- Tüm çok adımlı işlemler Firestore `runTransaction` ile atomik olarak gerçekleştirilir
- Özellik tabanlı testler `glados` paketi ile yazılır, minimum 100 iterasyon çalıştırılır
- Checkpoint görevleri artımlı doğrulama noktalarıdır
