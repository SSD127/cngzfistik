# Teknik Tasarım Dokümanı — Fıstık Komisyon Platformu

## Genel Bakış

Fıstık Komisyon Platformu, bir fıstık komisyoncusunun günlük operasyonlarını (emanet fıstık takibi, satış/alım, kasa yönetimi, depo takibi, raporlama) dijitalleştiren tek kod tabanıyla hem web hem mobil üzerinde çalışan bir yönetim sistemidir.

**Teknoloji Seçimleri:**

| Katman | Teknoloji | Gerekçe |
|---|---|---|
| UI / İstemci | Flutter (web + mobil) | Tek kod tabanı, ücretsiz |
| Veritabanı | Firebase Firestore | Gerçek zamanlı, offline destek, Spark Plan |
| Kimlik Doğrulama | Firebase Authentication | E-posta/şifre, ücretsiz |
| Dosya Depolama | Firebase Storage | Belge yükleme, Spark Plan |
| Hosting | Firebase Hosting | Flutter web deploy, ücretsiz |
| State Management | Riverpod | Compile-time güvenli, test edilebilir |
| Navigasyon | GoRouter | Deep link + web URL desteği |
| PDF Üretimi | pdf (pub.dev) | İstemci tarafı, sunucu gerektirmez |
| Para Birimi | integer (kuruş) | Float hatalarını önler, muhasebe güvenliği |

---

## Mimari

### Genel Mimari Diyagramı

```mermaid
graph TD
    subgraph Flutter App
        UI[UI Katmanı\nWidgets / Screens]
        VM[ViewModel Katmanı\nRiverpod Providers]
        REPO[Repository Katmanı\nFirestore Abstraction]
    end

    subgraph Firebase
        AUTH[Authentication]
        FS[Firestore]
        ST[Storage]
        HOST[Hosting]
    end

    UI --> VM
    VM --> REPO
    REPO --> FS
    REPO --> ST
    VM --> AUTH
    Flutter App --> HOST
```

### Katmanlı Mimari

Uygulama üç ana katmandan oluşur:

1. **UI Katmanı** — Flutter widget'ları ve ekranlar. İş mantığı içermez; yalnızca ViewModel'den gelen state'i gösterir.
2. **ViewModel Katmanı** — Riverpod `AsyncNotifier` / `Notifier` provider'ları. İş kurallarını uygular, Repository'yi çağırır.
3. **Repository Katmanı** — Firestore ve Storage erişimini soyutlar. Tüm Firestore transaction ve batch işlemleri burada gerçekleşir.

### Flutter Klasör Yapısı

```
lib/
├── main.dart
├── firebase_options.dart
├── app/
│   ├── app.dart                  # MaterialApp + GoRouter kurulumu
│   └── router.dart               # Tüm route tanımları
├── core/
│   ├── constants/
│   │   ├── firestore_paths.dart  # Koleksiyon yolları sabitleri
│   │   └── app_constants.dart
│   ├── extensions/
│   ├── utils/
│   │   ├── transaction_number.dart
│   │   └── token_generator.dart
│   └── widgets/                  # Paylaşılan UI bileşenleri
├── features/
│   ├── auth/
│   │   ├── data/auth_repository.dart
│   │   ├── presentation/login_screen.dart
│   │   └── providers/auth_provider.dart
│   ├── customers/
│   │   ├── data/customer_repository.dart
│   │   ├── domain/customer_model.dart
│   │   ├── presentation/
│   │   └── providers/
│   ├── inventory/                # Emanet fıstık + depo
│   │   ├── data/
│   │   ├── domain/
│   │   ├── presentation/
│   │   └── providers/
│   ├── sales/                    # Satış işlemleri
│   ├── purchases/                # Alım işlemleri
│   ├── cash/                     # Kasa yönetimi
│   ├── expenses/                 # Gider yönetimi
│   ├── reports/                  # Raporlama
│   ├── receipts/                 # Fiş oluşturma/yazdırma
│   ├── vault/                    # Kasa emaneti (döviz/altın)
│   ├── pistachio_types/          # Fıstık cinsi + özellik şablonları
│   └── customer_page/            # Salt-okunur müşteri sayfası
└── services/
    ├── pdf_service.dart
    ├── backup_service.dart
    └── audit_log_service.dart
```

---

## Bileşenler ve Arayüzler

### Kimlik Doğrulama ve Yetkilendirme Akışı

```mermaid
flowchart TD
    A[Uygulama Başlatılır] --> B{Firebase Auth\nDurumu?}
    B -- Oturum Açık --> C{Kullanıcı Rolü?}
    B -- Oturum Kapalı --> D[/login]
    C -- owner/employee/readonly --> E[/admin/dashboard]
    C -- Müşteri Token --> F[/c/:token]
    D -- Başarılı Giriş --> C
    F -- Token Geçersiz --> G[404 Sayfası]
```

**Rol Hiyerarşisi (Gereksinim 25):**

| Rol | Yetkiler |
|---|---|
| `owner` | Tüm işlemler + kullanıcı yönetimi + kritik silme |
| `employee` | Tüm işlemler (silme hariç) |
| `readonly` | Yalnızca görüntüleme |

Roller Firestore `users/{uid}` dokümanındaki `role` alanından okunur. Firestore Security Rules bu rolleri doğrular.

### Temel Ekranlar ve Navigasyon

```
/login                          → Giriş ekranı
/admin
  /dashboard                   → Özet gösterge paneli
  /customers                   → Müşteri listesi
  /customers/:id               → Müşteri detay
  /customers/:id/inventory     → Emanet fıstık hareketleri
  /customers/:id/cash          → Kasa hareketleri
  /inventory
    /deposits                  → Emanet fıstık girişi
    /warehouses                → Depo yönetimi
    /transfers                 → Depo transferleri
  /sales/new                   → Yeni satış
  /purchases/new               → Yeni alım
  /cash
    /deposit                   → Para girişi
    /withdrawal                → Para çıkışı
  /expenses                    → Gider listesi + yeni gider
  /reports
    /monthly                   → Aylık müşteri raporu
    /cash-flow                 → Kasa hareketlilik raporu
    /expense                   → Gider raporu
    /stock                     → Depo stok raporu
  /vault                       → Kasa emaneti (döviz/altın)
  /pistachio-types             → Fıstık cinsi + özellik şablonları
  /settings                   → Kullanıcı ve sistem ayarları
/c/:token                      → Müşteri salt-okunur sayfası
```

### Fiş Oluşturma Bileşeni

`PdfService` sınıfı `pdf` paketi kullanarak istemci tarafında PDF üretir. Sunucu gerektirmez. Fiş içeriği:
- İşlem numarası, tarih/saat
- Müşteri adı
- İşlem türü, Fıstık_Cinsi, miktar, Kur, İç_Gramaj
- Toplam tutar, güncel Kasa bakiyesi

Yazdırma: `printing` paketi ile tarayıcı/sistem yazdırma diyaloğu açılır.

**Türkçe Font:** PDF'lerde Türkçe karakter desteği için UTF-8 gömülü font (örn. Roboto veya Noto Sans) kullanılır. `pdf` paketi custom font embedding destekler; `assets/fonts/` altına font dosyaları eklenir.

---

## Veri Modelleri

### Firestore Koleksiyon Yapısı

```
firestore/
├── users/                          # Kullanıcı profilleri ve roller
├── customers/                      # Müşteri kayıtları
├── customer_pages/                 # Token → customerId eşlemesi (güvenli erişim)
├── pistachio_types/                # Fıstık cinsi tanımları
├── pistachio_attributes/           # Dinamik özellik şablonları (Gereksinim 30)
├── warehouses/                     # Depo tanımları
├── price_history/                  # Günlük Kur geçmişi
├── inventory_deposits/             # Emanet fıstık girişleri
├── stock_movements/                # Tüm stok hareketleri (Gereksinim 15)
├── warehouse_summaries/            # Depo bazlı özet stok (denormalize)
├── sales/                          # Satış işlemleri
├── purchases/                      # Alım işlemleri
├── cash_movements/                 # Kasa hareketleri
├── expenses/                       # Gider kayıtları
├── receipts/                       # Fiş kayıtları
├── vault_items/                    # Kasa emaneti (döviz/altın)
├── vault_movements/                # Kasa emaneti hareketleri
├── monthly_summaries/              # Aylık rapor özetleri (Gereksinim 22)
├── audit_logs/                     # Denetim kayıtları (Gereksinim 19)
├── transaction_counters/           # Benzersiz işlem numarası sayaçları
└── system_settings/                # Şema versiyonu ve sistem ayarları
```

### Doküman Yapıları

#### `users/{uid}`
```json
{
  "uid": "string",
  "email": "string",
  "displayName": "string",
  "role": "owner | employee | readonly",
  "createdAt": "Timestamp",
  "isActive": "boolean"
}
```

#### `customers/{customerId}`
```json
{
  "id": "string",
  "firstName": "string",
  "lastName": "string",
  "phone": "string",
  "cashBalanceCents": "integer (kuruş cinsinden, negatif olabilir)",
  "isDebtor": "boolean",
  "isDeleted": "boolean",
  "deletedAt": "Timestamp | null",
  "deletedBy": "string | null",
  "createdAt": "Timestamp",
  "updatedAt": "Timestamp"
}
```

#### `customer_pages/{token}` — Token → Müşteri eşlemesi
```json
{
  "customerId": "string",
  "isActive": "boolean",
  "createdAt": "Timestamp"
}
```

Token, doküman ID'si olarak kullanılır. Müşteri sayfasına erişimde önce bu koleksiyondan `customerId` çözülür, ardından müşteri verisi okunur. Eski token iptal edildiğinde `isActive: false` yapılır, yeni token için yeni doküman oluşturulur.

#### `pistachio_types/{typeId}`
```json
{
  "id": "string",
  "name": "string",
  "defaultInnerGramRatio": "number (0-1 arası, örn. 0.45)",
  "currentPricePerKgCents": "integer (kuruş cinsinden)",
  "isActive": "boolean",
  "createdAt": "Timestamp"
}
```

#### `pistachio_attributes/{attributeId}` — Gereksinim 30
```json
{
  "id": "string",
  "name": "string",
  "dataType": "select | numeric",
  "options": ["string"] ,
  "isPriceMultiplier": "boolean",
  "multiplierValue": "number | null",
  "isActive": "boolean",
  "createdAt": "Timestamp"
}
```

#### `warehouses/{warehouseId}`
```json
{
  "id": "string",
  "name": "string",
  "address": "string",
  "isActive": "boolean",
  "createdAt": "Timestamp"
}
```

#### `price_history/{priceId}` — Gereksinim 3, 17
```json
{
  "id": "string",
  "pistachioTypeId": "string",
  "pricePerKgCents": "integer (kuruş cinsinden)",
  "recordedAt": "Timestamp",
  "recordedBy": "string (uid)"
}
```

#### `inventory_deposits/{depositId}` — Gereksinim 5
```json
{
  "id": "string",
  "customerId": "string",
  "pistachioTypeId": "string",
  "warehouseId": "string",
  "quantityKg": "number",
  "date": "Timestamp",
  "attributes": {
    "attributeId": "string | number"
  },
  "isDeleted": "boolean",
  "correctionLog": [
    {
      "previousValue": "number",
      "newValue": "number",
      "correctedAt": "Timestamp",
      "correctedBy": "string"
    }
  ],
  "createdAt": "Timestamp",
  "createdBy": "string"
}
```

#### `stock_movements/{movementId}` — Gereksinim 15
```json
{
  "id": "string",
  "type": "deposit | sale | purchase | transfer_in | transfer_out | reversal",
  "warehouseId": "string",
  "customerId": "string | null",
  "pistachioTypeId": "string",
  "quantityKg": "number",
  "referenceId": "string (ilgili işlem ID)",
  "date": "Timestamp"
}
```

#### `warehouse_summaries/{warehouseId}__{pistachioTypeId}` — Denormalize özet
```json
{
  "warehouseId": "string",
  "pistachioTypeId": "string",
  "totalQuantityKg": "number",
  "updatedAt": "Timestamp"
}
```

#### `sales/{saleId}` — Gereksinim 6, 17
```json
{
  "id": "string",
  "transactionNumber": "string",
  "customerId": "string",
  "pistachioTypeId": "string",
  "warehouseId": "string",
  "quantityKg": "number",
  "pricePerKgCentsAtTime": "integer (kuruş, işlem anında sabitlenir)",
  "innerGramRatioAtTime": "number",
  "totalAmountCents": "integer (kuruş cinsinden)",
  "date": "Timestamp",
  "receiptId": "string",
  "isCancelled": "boolean",
  "cancellationReason": "string | null",
  "cancelledAt": "Timestamp | null",
  "isDeleted": "boolean",
  "createdBy": "string"
}
```

#### `purchases/{purchaseId}` — Gereksinim 7
```json
{
  "id": "string",
  "transactionNumber": "string",
  "customerId": "string",
  "pistachioTypeId": "string",
  "warehouseId": "string",
  "quantityKg": "number",
  "pricePerKgCentsAtTime": "integer (kuruş)",
  "totalAmountCents": "integer (kuruş)",
  "source": "warehouse | external",
  "paymentMethod": "cash_balance | cash",
  "date": "Timestamp",
  "receiptId": "string",
  "isCancelled": "boolean",
  "cancellationReason": "string | null",
  "isDeleted": "boolean",
  "createdBy": "string"
}
```

#### `cash_movements/{movementId}` — Gereksinim 8
```json
{
  "id": "string",
  "transactionNumber": "string",
  "customerId": "string",
  "type": "deposit | withdrawal | sale_credit | purchase_debit | reversal",
  "amountCents": "integer (kuruş, negatif olabilir)",
  "description": "string",
  "referenceId": "string | null",
  "date": "Timestamp",
  "receiptId": "string | null",
  "isCancelled": "boolean",
  "createdBy": "string"
}
```

#### `expenses/{expenseId}` — Gereksinim 10
```json
{
  "id": "string",
  "date": "Timestamp",
  "category": "transport | labor | invoice | credit_card | other",
  "amountCents": "integer (kuruş)",
  "description": "string",
  "documentUrl": "string | null",
  "documentPath": "string | null",
  "isDeleted": "boolean",
  "deletedAt": "Timestamp | null",
  "deletedBy": "string | null",
  "createdBy": "string",
  "createdAt": "Timestamp"
}
```

#### `receipts/{receiptId}` — Gereksinim 9, 27
```json
{
  "id": "string",
  "receiptNumber": "string",
  "type": "sale | purchase | cash_deposit | cash_withdrawal | vault_deposit | vault_withdrawal",
  "customerId": "string",
  "customerName": "string (snapshot — müşteri adı değişse bile korunur)",
  "date": "Timestamp",
  "pistachioType": "string | null (snapshot)",
  "quantityKg": "number | null",
  "pricePerKgCents": "integer | null (snapshot)",
  "totalAmountCents": "integer (kuruş)",
  "cashBalanceAfterCents": "integer (kuruş, snapshot)",
  "referenceId": "string",
  "createdAt": "Timestamp"
}
```

#### `vault_items/{vaultId}` — Gereksinim 29
```json
{
  "id": "string",
  "ownerName": "string",
  "customerId": "string | null",
  "type": "USD | EUR | TL | gold_gram | other",
  "otherTypeDescription": "string | null",
  "balanceCents": "integer (TL için kuruş; döviz/altın için en küçük birim × 100)",
  "createdAt": "Timestamp",
  "updatedAt": "Timestamp"
}
```

#### `vault_movements/{movementId}` — Gereksinim 29
```json
{
  "id": "string",
  "vaultItemId": "string",
  "type": "deposit | withdrawal",
  "amountCents": "integer",
  "date": "Timestamp",
  "receiptId": "string | null",
  "createdBy": "string"
}
```

#### `monthly_summaries/{year}_{month}_{customerId}` — Gereksinim 22
```json
{
  "year": "number",
  "month": "number",
  "customerId": "string",
  "totalSoldKg": "number",
  "totalPurchasedKg": "number",
  "totalSalesAmountCents": "integer (kuruş)",
  "endingCashBalanceCents": "integer (kuruş)",
  "updatedAt": "Timestamp"
}
```

#### `audit_logs/{logId}` — Gereksinim 19
```json
{
  "id": "string",
  "userId": "string",
  "action": "string",
  "collection": "string",
  "documentId": "string",
  "previousValue": "object | null",
  "newValue": "object | null",
  "timestamp": "Timestamp"
}
```

#### `transaction_counters/{type}` — Gereksinim 27
```json
{
  "type": "sale | purchase | cash | receipt",
  "lastNumber": "number",
  "prefix": "string"
}
```

### Müşteri Bazlı Emanet Fıstık Özeti (Denormalize)

Müşteri dokümanına gömülü olarak tutulur — `customers/{customerId}/inventory_summary` alt koleksiyonu:

```json
{
  "pistachioTypeId": "string",
  "warehouseId": "string",
  "quantityKg": "number"
}
```

Bu sayede müşteri listesi ekranında her müşteri için ayrı sorgu yapılmaz.

---

## Güvenlik Kuralları Yaklaşımı

### Firestore Security Rules Stratejisi (Gereksinim 13, 26)

Token erişimi `customer_pages/{token}` koleksiyonu üzerinden çözülür. Bu yaklaşım:
- `customerId` scope sorununu ortadan kaldırır
- Kural yazımını temizler
- Token iptali için `isActive` flag yeterlidir

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    function isAuthenticated() {
      return request.auth != null;
    }

    function getUserRole() {
      return get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role;
    }

    function isOwner() {
      return isAuthenticated() && getUserRole() == 'owner';
    }

    function isEmployee() {
      return isAuthenticated() && getUserRole() in ['owner', 'employee'];
    }

    function isReadonly() {
      return isAuthenticated() && getUserRole() in ['owner', 'employee', 'readonly'];
    }

    // Müşteri sayfası token erişimi — customer_pages koleksiyonu üzerinden
    match /customer_pages/{token} {
      allow read: if true; // Token çözümü için herkese açık okuma
      allow write: if isEmployee();
    }

    // Müşteriler — admin erişimi veya token ile ilişkili okuma
    match /customers/{customerId} {
      allow read: if isReadonly();
      allow create, update: if isEmployee();
      allow delete: if isOwner();
    }

    // Audit logs — istemci oluşturabilir, güncelleyemez/silemez
    match /audit_logs/{logId} {
      allow read: if isOwner();
      allow create: if isEmployee();
      allow update, delete: if false;
    }

    // Transaction counters — transaction içinde güncellenir
    match /transaction_counters/{type} {
      allow read: if isEmployee();
      allow write: if isEmployee();
    }

    // Satış — iptal dışında güncelleme yapılamaz
    match /sales/{saleId} {
      allow read: if isReadonly();
      allow create: if isEmployee();
      allow update: if isEmployee()
        && request.resource.data.diff(resource.data).affectedKeys()
            .hasOnly(['isCancelled', 'cancellationReason', 'cancelledAt']);
      allow delete: if false;
    }

    // Giderler
    match /expenses/{expenseId} {
      allow read: if isReadonly();
      allow create, update: if isEmployee();
      allow delete: if isOwner();
    }

    // Genel kural — diğer tüm koleksiyonlar
    match /{collection}/{docId} {
      allow read: if isReadonly();
      allow write: if isEmployee();
    }
  }
}
```

---

## Çevrimdışı Destek Yaklaşımı (Gereksinim 23)

Offline persistence yalnızca okuma/listeleme ekranları için etkinleştirilir. Kritik finansal işlemler (satış, alım, kasa hareketi, stok transferi) çevrimdışıyken engellenir — stale cache üzerinden işlem yapılması veri bozulmasına yol açabilir.

```dart
// main.dart içinde — sadece okuma için cache
await FirebaseFirestore.instance.settings = const Settings(
  persistenceEnabled: true,
  cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
);
```

**Kritik işlemlerde çevrimiçi kontrolü:**
```dart
// İşlem başlamadan önce bağlantı kontrolü
final connectivityResult = await Connectivity().checkConnectivity();
if (connectivityResult == ConnectivityResult.none) {
  throw OfflineException('Bu işlem internet bağlantısı gerektirir.');
}
```

**Senkronizasyon Bildirimi:** `FirebaseFirestore.instance.snapshotsInSync()` stream'i dinlenerek kullanıcıya çevrimdışı/çevrimiçi durumu gösterilir.

---

## Hata Yönetimi

### Transaction Hataları (Gereksinim 14)

Tüm çok adımlı işlemler (satış, alım, kasa hareketi, stok transferi) Firestore `runTransaction` içinde gerçekleştirilir. Transaction counter güncellemesi de aynı transaction içinde yapılır — race condition önlenir:

```dart
await FirebaseFirestore.instance.runTransaction((transaction) async {
  // 1. Okuma aşaması (tüm okumalar önce)
  final customerDoc = await transaction.get(customerRef);
  final warehouseDoc = await transaction.get(warehouseSummaryRef);
  final counterDoc = await transaction.get(counterRef);

  // 2. Doğrulama (en güncel snapshot üzerinde)
  final currentStock = warehouseDoc.data()!['totalQuantityKg'] as num;
  if (currentStock < quantityKg) {
    throw Exception('Yetersiz stok');
  }

  // 3. Yeni işlem numarası (transaction içinde — race condition yok)
  final newNumber = (counterDoc.data()!['lastNumber'] as int) + 1;
  transaction.update(counterRef, {'lastNumber': newNumber});

  // 4. Yazma aşaması (atomik)
  transaction.update(customerRef, {
    'cashBalanceCents': FieldValue.increment(totalAmountCents),
  });
  transaction.update(warehouseSummaryRef, {
    'totalQuantityKg': FieldValue.increment(-quantityKg),
  });
  transaction.set(saleRef, {...});
  transaction.set(cashMovementRef, {...});
  transaction.set(stockMovementRef, {...});
  transaction.set(auditLogRef, {...}); // Audit log aynı transaction içinde
});
```

Transaction başarısız olursa tüm değişiklikler otomatik geri alınır.

### Kullanıcıya Hata Bildirimi

- Yetersiz bakiye / stok → inline hata mesajı (form alanı altında)
- Ağ hatası → `SnackBar` ile bildirim + yeniden deneme butonu
- 5 MB dosya sınırı aşımı → yükleme öncesi istemci tarafı kontrol
- Geçersiz token → 404 ekranı

---

## Para Birimi Kuralları

Tüm parasal değerler **integer kuruş** olarak saklanır. Float kullanımı yasaktır.

```dart
// Doğru
int totalAmountCents = (quantityKg * pricePerKgCents * innerGramRatio).round();

// Yanlış — KULLANMA
double totalAmount = quantityKg * pricePerKg * innerGramRatio;
```

UI'da gösterim için:
```dart
String formatCents(int cents) {
  return '${(cents / 100).toStringAsFixed(2)} ₺';
}
```

## Firestore Index Planı

Composite index gerektiren sorgular `firestore.indexes.json` dosyasında tanımlanır:

| Koleksiyon | Alanlar | Sıralama |
|---|---|---|
| `cash_movements` | `customerId`, `date` | ASC |
| `sales` | `customerId`, `date` | DESC |
| `purchases` | `customerId`, `date` | DESC |
| `stock_movements` | `warehouseId`, `pistachioTypeId`, `date` | DESC |
| `expenses` | `category`, `date` | DESC |
| `expenses` | `isDeleted`, `date` | DESC |
| `monthly_summaries` | `customerId`, `year`, `month` | DESC |
| `inventory_deposits` | `customerId`, `pistachioTypeId`, `isDeleted` | ASC |

## Schema Versioning ve Migration

`system_settings/schema` dokümanı şema versiyonunu tutar:

```json
{
  "schemaVersion": 1,
  "updatedAt": "Timestamp"
}
```

Uygulama başlangıcında mevcut versiyon kontrol edilir. Versiyon uyumsuzluğunda `MigrationService` ilgili migration'ı çalıştırır. Her migration idempotent olmalıdır (birden fazla çalıştırılabilir).

```dart
class MigrationService {
  static const int currentVersion = 1;

  Future<void> runMigrations() async {
    final doc = await _settingsRef.get();
    final version = doc.data()?['schemaVersion'] ?? 0;
    if (version < currentVersion) {
      // Migration'ları sırayla çalıştır
      for (int v = version + 1; v <= currentVersion; v++) {
        await _runMigration(v);
      }
    }
  }
}
```

## Test Stratejisi

Bu özellik için test yaklaşımı şu katmanları kapsar:

**Birim Testleri:**
- Repository sınıfları için mock Firestore ile birim testleri
- Fiyat hesaplama mantığı (Kur × miktar × İç_Gramaj) için saf fonksiyon testleri
- Token üretimi ve benzersizlik doğrulaması
- Soft delete, iptal ve ters kayıt mantığı

**Widget Testleri:**
- Kritik form ekranları (satış, alım, kasa hareketi) için widget testleri
- Müşteri_Sayfası salt-okunur görünüm doğrulaması

**Entegrasyon Testleri:**
- Firebase Emulator Suite kullanılarak gerçek Firestore transaction testleri
- Güvenlik kuralları testleri (`@firebase/rules-unit-testing`)

**Özellik Tabanlı Testler (Property-Based Testing):**
Aşağıdaki Correctness Properties bölümünde tanımlanan özellikler için `dart_test` + `glados` paketi kullanılarak özellik tabanlı testler yazılır. Her test minimum 100 iterasyon çalıştırılır.


---

## Correctness Properties

*Bir özellik (property), sistemin tüm geçerli çalışmalarında doğru olması gereken bir karakteristik veya davranıştır — temelde sistemin ne yapması gerektiğine dair biçimsel bir ifadedir. Özellikler, insan tarafından okunabilir spesifikasyonlar ile makine tarafından doğrulanabilir doğruluk garantileri arasındaki köprüyü oluşturur.*

Aşağıdaki özellikler `glados` paketi kullanılarak Dart'ta özellik tabanlı testler olarak uygulanacaktır. Her test minimum 100 iterasyon çalıştırılır.

---

### Özellik 1: Token Benzersizliği ve Kalitesi

*Herhangi bir* N sayıda üretilen Müşteri_Sayfası URL tokeni için, tüm tokenlar birbirinden farklı olmalı, her token en az 32 karakter uzunluğunda olmalı ve yalnızca URL-güvenli karakterler içermelidir.

**Doğrular: Gereksinim 1.5, 18.1**

---

### Özellik 2: Token Tabanlı Erişim İzolasyonu

*Herhangi bir* geçerli müşteri token'ı ile yapılan sorguda, dönen veriler yalnızca o token'a sahip müşteriye ait olmalı; başka hiçbir müşterinin verisi dönmemelidir.

**Doğrular: Gereksinim 1.6**

---

### Özellik 3: Aktif Bakiyeli Müşteri Silme Engeli

*Herhangi bir* müşteri için — kasa bakiyesi sıfırdan farklıysa veya emanet fıstık miktarı sıfırdan büyükse — silme girişimi reddedilmeli ve müşteri kaydı değişmeden kalmalıdır.

**Doğrular: Gereksinim 2.4, 2.5**

---

### Özellik 4: En Güncel Kur Seçimi

*Herhangi bir* fıstık cinsi için birden fazla Kur kaydı mevcut olduğunda, satış hesaplamalarında kullanılan Kur değeri her zaman en son kayıt tarihine sahip olan olmalıdır.

**Doğrular: Gereksinim 3.3, 3.5**

---

### Özellik 5: Emanet Girişi Tutarlılığı

*Herhangi bir* geçerli emanet fıstık girişi için, işlem sonrası müşterinin ilgili fıstık cinsi bakiyesindeki artış ile depo stokundaki artış, girilen miktara tam olarak eşit olmalıdır.

**Doğrular: Gereksinim 5.1, 5.2**

---

### Özellik 6: Fiyat Hesaplama Doğruluğu

*Herhangi bir* geçerli miktar (kg), Kur (TL/kg) ve İç_Gramaj (0–1 arası) kombinasyonu için, hesaplanan satış tutarı `miktar × Kur × İç_Gramaj` formülüne tam olarak eşit olmalıdır.

**Doğrular: Gereksinim 6.2**

---

### Özellik 7: Bakiye Yetersizliğinde İşlem Reddi

*Herhangi bir* işlem türü (satış, alım, para çekme, emanet iadesi) için — talep edilen miktar mevcut bakiyeyi (emanet fıstık veya kasa) aşıyorsa — işlem reddedilmeli ve tüm bakiyeler işlem öncesi değerlerinde kalmalıdır.

**Doğrular: Gereksinim 6.3, 7.2, 7.3, 8.5, 29.4**

---

### Özellik 8: Satış Transaction Tutarlılığı

*Herhangi bir* geçerli satış işlemi için, işlem sonrası şu üç değişim aynı anda gerçekleşmeli ve tutarlı olmalıdır: müşterinin emanet fıstık bakiyesi `miktar` kadar azalmalı, depo stoku `miktar` kadar düşmeli, müşterinin kasa bakiyesi hesaplanan tutar kadar artmalıdır.

**Doğrular: Gereksinim 6.4**

---

### Özellik 9: Dosya Boyutu Sınırı

*Herhangi bir* dosya yükleme girişimi için — dosya boyutu 5 MB'ı aşıyorsa — yükleme işlemi başlamadan önce reddedilmeli ve kullanıcıya bildirim gösterilmelidir.

**Doğrular: Gereksinim 13.3, 13.4**

---

### Özellik 10: Negatif Stok Engeli

*Herhangi bir* işlem dizisi (satış, alım, transfer) uygulandıktan sonra, hiçbir deponun hiçbir fıstık cinsi için stok miktarı negatife düşmemelidir.

**Doğrular: Gereksinim 15.4**

---

### Özellik 11: Kur Sabitleme

*Herhangi bir* satış veya alım işlemi kaydedildikten sonra, o işlemdeki `pricePerKgAtTime` alanı sonraki Kur güncellemelerinden bağımsız olarak değişmeden kalmalıdır.

**Doğrular: Gereksinim 17.1, 17.2**

---

### Özellik 12: Soft Delete Round-Trip

*Herhangi bir* kayıt (müşteri, gider, işlem) soft delete ile silindiğinde, kayıt varsayılan listeleme sorgularında görünmemeli; ancak doğrudan ID ile erişildiğinde `isDeleted: true` olarak hâlâ erişilebilir olmalıdır.

**Doğrular: Gereksinim 20.1, 20.2, 20.4**

---

### Özellik 13: İptal Ters Kayıt Round-Trip

*Herhangi bir* işlem (satış, alım, kasa hareketi) yapılıp ardından iptal edildiğinde, tüm etkilenen bakiyeler (emanet fıstık, depo stoku, kasa) işlem öncesi değerlerine tam olarak dönmelidir.

**Doğrular: Gereksinim 24.1, 24.2**

---

### Özellik 14: Fıstık Partisi Özellik Değerleri Dayanıklılığı

*Herhangi bir* fıstık partisi için kaydedilen özellik değerleri (dinamik attribute'lar), ilgili özellik şablonu silinse dahi, o partinin kaydında değişmeden korunmalıdır.

**Doğrular: Gereksinim 30.4, 30.9**