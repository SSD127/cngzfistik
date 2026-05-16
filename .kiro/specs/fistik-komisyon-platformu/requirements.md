# Gereksinimler Dokümanı

## Giriş

Fıstık Komisyon Platformu, bir fıstık komisyoncusunun günlük iş operasyonlarını dijitalleştiren bir yönetim sistemidir. Platform; müşteri emanet fıstık takibini, satış ve alım işlemlerini, kasa yönetimini, depo takibini ve raporlamayı kapsar. Flutter ile geliştirilecek olup hem web hem mobil üzerinde çalışacak; altyapı olarak Firebase Spark Plan kullanılacaktır.

---

## Sözlük

- **Platform**: Fıstık Komisyon Platformu — bu dokümanın konu aldığı yazılım sistemi
- **Admin**: Sistemi tam yetkiyle yöneten komisyoncu kullanıcısı (dayı)
- **Müşteri**: Fıstığını depoya emanet bırakan veya fıstık satın alan kişi; platforma salt-okunur erişimi vardır
- **Müşteri_Sayfası**: Her müşteriye özel, benzersiz URL ile erişilen salt-okunur görüntüleme sayfası
- **Emanet_Fıstık**: Müşterinin satılmak üzere depoya bıraktığı fıstık miktarı
- **Kasa**: Müşterilere ait para bakiyelerinin tutulduğu sanal para kasası
- **Depo**: Fıstıkların fiziksel olarak saklandığı yer; platformda birden fazla depo tanımlanabilir
- **Kur**: Admin tarafından günlük olarak manuel girilen fıstık birim fiyatı (TL/kg)
- **Fiş**: Satış, alım veya para hareketi sonrası oluşturulan yazdırılabilir belge
- **Gider**: Nakliye, hammaliye, fatura, kredi kartı ekstresi gibi işletme giderleri
- **Fıstık_Cinsi**: Farklı fıstık çeşitlerini tanımlayan kategori (örn. Antep, Siirt)
- **İç_Gramaj**: Fıstığın iç ağırlık oranı; fiyat hesaplamalarını etkileyen bir parametre

---

## Gereksinimler

### Gereksinim 1: Kullanıcı Kimlik Doğrulama ve Yetkilendirme

**Kullanıcı Hikayesi:** Bir admin olarak sisteme güvenli giriş yapmak istiyorum; böylece yalnızca yetkili kişilerin verileri yönetebilmesini sağlayabilirim.

#### Kabul Kriterleri

1. THE Platform SHALL Firebase Authentication kullanarak admin kullanıcısı için e-posta ve şifre tabanlı kimlik doğrulama sağlamalıdır.
2. WHEN admin geçerli kimlik bilgileriyle giriş yaptığında, THE Platform SHALL admin paneline yönlendirmelidir.
3. IF admin geçersiz kimlik bilgileri girerse, THEN THE Platform SHALL açıklayıcı bir hata mesajı göstermelidir.
4. WHEN admin oturumu kapattığında, THE Platform SHALL oturum bilgilerini temizlemeli ve giriş sayfasına yönlendirmelidir.
5. THE Platform SHALL her Müşteri_Sayfası için benzersiz, tahmin edilemez bir URL token oluşturmalıdır.
6. WHEN bir kullanıcı geçerli Müşteri_Sayfası URL'sine eriştiğinde, THE Platform SHALL kimlik doğrulaması gerektirmeksizin yalnızca o müşteriye ait verileri göstermelidir.
7. IF geçersiz veya süresi dolmuş bir Müşteri_Sayfası URL'sine erişilirse, THEN THE Platform SHALL "Sayfa bulunamadı" mesajı göstermelidir.
8. THE Platform SHALL Müşteri_Sayfası üzerinden herhangi bir veri değişikliği işlemine izin vermemelidir.

---

### Gereksinim 2: Müşteri Yönetimi

**Kullanıcı Hikayesi:** Bir admin olarak müşteri ekleyip çıkarabilmek istiyorum; böylece her müşterinin fıstık ve para hareketlerini ayrı ayrı takip edebileyim.

#### Kabul Kriterleri

1. THE Admin SHALL yeni müşteri oluşturabilmelidir; her müşteri için ad, soyad ve iletişim bilgisi girilmelidir.
2. WHEN yeni müşteri oluşturulduğunda, THE Platform SHALL o müşteriye özgü benzersiz bir Müşteri_Sayfası URL'si üretmelidir.
3. THE Admin SHALL mevcut müşteri bilgilerini güncelleyebilmelidir.
4. WHEN admin bir müşteriyi silmek istediğinde, THE Platform SHALL müşteriye ait aktif Emanet_Fıstık veya Kasa bakiyesi bulunup bulunmadığını kontrol etmelidir.
5. IF silinmek istenen müşterinin aktif bakiyesi veya emanet fıstığı varsa, THEN THE Platform SHALL silme işlemini engellemeli ve uyarı mesajı göstermelidir.
6. THE Admin SHALL tüm müşterilerin listesini, her birinin toplam emanet fıstık miktarı ve kasa bakiyesiyle birlikte görüntüleyebilmelidir.
7. THE Admin SHALL Müşteri_Sayfası URL'sini kopyalayabilmeli veya paylaşabilmelidir.

---

### Gereksinim 3: Fıstık Cinsi ve Fiyat Yönetimi

**Kullanıcı Hikayesi:** Bir admin olarak fıstık çeşitlerini ve günlük fiyatları yönetmek istiyorum; böylece satış hesaplamalarının doğru yapılmasını sağlayabilirim.

#### Kabul Kriterleri

1. THE Admin SHALL yeni Fıstık_Cinsi tanımlayabilmelidir; her cins için ad ve varsayılan İç_Gramaj değeri girilmelidir.
2. THE Admin SHALL mevcut Fıstık_Cinsi bilgilerini güncelleyebilmelidir.
3. THE Admin SHALL her Fıstık_Cinsi için günlük Kur değerini manuel olarak girebilmelidir.
4. WHEN Kur değeri girildiğinde, THE Platform SHALL girişin tarih ve saatini kaydetmelidir.
5. THE Platform SHALL her Fıstık_Cinsi için en güncel Kur değerini satış hesaplamalarında kullanmalıdır.
6. THE Platform SHALL geçmiş Kur değerlerini tarih bazlı olarak saklamalıdır.
7. WHILE Kur değeri girilmemişse, THE Platform SHALL o güne ait satış işlemlerinde kullanıcıyı uyarmalıdır.
8. THE Admin SHALL İç_Gramaj değerini fiyat hesaplama formülüne dahil edebilmelidir.

---

### Gereksinim 4: Depo Yönetimi

**Kullanıcı Hikayesi:** Bir admin olarak birden fazla depoyu yönetmek istiyorum; böylece sezonluk kapasite artışlarında stok takibini doğru yapabilirim.

#### Kabul Kriterleri

1. THE Admin SHALL yeni depo tanımlayabilmelidir; her depo için ad ve adres bilgisi girilmelidir.
2. THE Admin SHALL mevcut depo bilgilerini güncelleyebilmelidir.
3. THE Admin SHALL depoları aktif veya pasif olarak işaretleyebilmelidir.
4. WHILE bir depo pasif durumdaysa, THE Platform SHALL o depoya yeni stok girişine izin vermemelidir.
5. THE Platform SHALL her depodaki toplam fıstık miktarını Fıstık_Cinsi bazında göstermelidir.
6. THE Admin SHALL fıstık transferini bir depodan diğerine gerçekleştirebilmelidir; transfer kaydı tarih ve miktar bilgisiyle saklanmalıdır.

---

### Gereksinim 5: Emanet Fıstık Takibi

**Kullanıcı Hikayesi:** Bir admin olarak müşterilerin depoya bıraktığı fıstıkları kayıt altına almak istiyorum; böylece kimin ne kadar fıstığının depoda olduğunu her zaman bilebilirim.

#### Kabul Kriterleri

1. THE Admin SHALL müşteri adına emanet fıstık girişi yapabilmelidir; giriş için müşteri, Fıstık_Cinsi, miktar (kg), depo ve tarih bilgileri zorunludur.
2. WHEN emanet fıstık girişi kaydedildiğinde, THE Platform SHALL ilgili müşterinin Emanet_Fıstık bakiyesini güncellemeli ve depodaki stoku artırmalıdır.
3. THE Platform SHALL her müşteri için Fıstık_Cinsi bazında toplam Emanet_Fıstık miktarını göstermelidir.
4. THE Admin SHALL emanet fıstık giriş kaydını düzeltebilmelidir; her düzeltme işlemi önceki değer, yeni değer ve düzeltme tarihi ile loglanmalıdır.
5. THE Platform SHALL tüm emanet fıstık hareketlerini kronolojik sırayla listeleyebilmelidir.

---

### Gereksinim 6: Satış İşlemleri

**Kullanıcı Hikayesi:** Bir admin olarak müşteri fıstığını satabilmek istiyorum; böylece satış tutarı otomatik hesaplanarak müşterinin kasa bakiyesine eklensin.

#### Kabul Kriterleri

1. THE Admin SHALL müşteri adına satış işlemi başlatabilmelidir; satış için müşteri, Fıstık_Cinsi, miktar (kg) ve depo bilgileri zorunludur.
2. WHEN satış işlemi başlatıldığında, THE Platform SHALL o Fıstık_Cinsi için geçerli günlük Kur değerini ve İç_Gramaj parametresini kullanarak satış tutarını hesaplamalıdır.
3. IF satılmak istenen miktar müşterinin ilgili depodaki Emanet_Fıstık miktarını aşıyorsa, THEN THE Platform SHALL işlemi engellemeli ve mevcut bakiyeyi göstermelidir.
4. WHEN satış işlemi onaylandığında, THE Platform SHALL müşterinin Emanet_Fıstık bakiyesini azaltmalı, depodaki stoku düşürmeli ve hesaplanan tutarı müşterinin Kasa bakiyesine eklemeli ve Fiş oluşturmalıdır.
5. THE Platform SHALL her satış işlemini; tarih, müşteri, Fıstık_Cinsi, miktar, uygulanan Kur, İç_Gramaj ve toplam tutar bilgileriyle kaydetmelidir.
6. THE Admin SHALL oluşturulan Fişi yazdırabilmeli veya PDF olarak indirebilmelidir.

---

### Gereksinim 7: Fıstık Alım İşlemleri

**Kullanıcı Hikayesi:** Bir admin olarak müşteri adına fıstık alabilmek istiyorum; böylece müşterinin kasa bakiyesi veya getirdiği para karşılığında fıstık temin edebileyim.

#### Kabul Kriterleri

1. THE Admin SHALL müşteri adına fıstık alım işlemi başlatabilmelidir; alım için müşteri, Fıstık_Cinsi, miktar (kg), kaynak (depodan veya dışarıdan) ve ödeme yöntemi (kasa bakiyesinden veya nakit) bilgileri zorunludur.
2. WHEN ödeme yöntemi "kasa bakiyesinden" seçildiğinde, THE Platform SHALL müşterinin mevcut Kasa bakiyesinin alım tutarını karşılayıp karşılamadığını kontrol etmelidir.
3. IF müşterinin Kasa bakiyesi alım tutarını karşılamıyorsa, THEN THE Platform SHALL işlemi engellemeli ve eksik tutarı göstermelidir.
4. WHEN alım işlemi onaylandığında, THE Platform SHALL seçilen kaynağa göre depo stokunu güncellemeli, müşterinin Kasa bakiyesini düşürmeli (kasa ödemesinde) ve Fiş oluşturmalıdır.
5. WHERE kaynak "dışarıdan" seçildiğinde, THE Platform SHALL alınan fıstığı seçilen depoya stok olarak eklemeli ve alım maliyetini gider olarak kaydetmelidir.
6. THE Platform SHALL her alım işlemini; tarih, müşteri, Fıstık_Cinsi, miktar, uygulanan Kur, kaynak, ödeme yöntemi ve toplam tutar bilgileriyle kaydetmelidir.

---

### Gereksinim 8: Kasa ve Para Yönetimi

**Kullanıcı Hikayesi:** Bir admin olarak her müşterinin para bakiyesini takip etmek istiyorum; böylece kimin kasada ne kadar parası olduğunu ve para hareketlerini görebileyim.

#### Kabul Kriterleri

1. THE Platform SHALL her müşteri için ayrı bir Kasa bakiyesi tutmalıdır.
2. THE Admin SHALL müşteri adına nakit para girişi kaydedebilmelidir; giriş için müşteri, tutar ve açıklama bilgileri zorunludur.
3. WHEN nakit para girişi kaydedildiğinde, THE Platform SHALL müşterinin Kasa bakiyesini artırmalı ve hareketi loglamalıdır.
4. THE Admin SHALL müşteriye para ödemesi yapabilmelidir; ödeme için müşteri ve tutar bilgileri zorunludur.
5. IF ödeme tutarı müşterinin Kasa bakiyesini aşıyorsa, THEN THE Platform SHALL işlemi engellemeli ve mevcut bakiyeyi göstermelidir.
6. WHEN para ödemesi yapıldığında, THE Platform SHALL müşterinin Kasa bakiyesini düşürmeli, hareketi loglamalı ve Fiş oluşturmalıdır.
7. THE Platform SHALL her Kasa hareketini; tarih, müşteri, hareket türü (giriş/çıkış/satış/alım), tutar ve açıklama bilgileriyle kaydetmelidir.
8. THE Admin SHALL belirli bir müşterinin tüm Kasa hareketlerini tarih aralığına göre filtreleyerek görüntüleyebilmelidir.

---

### Gereksinim 9: Fiş Oluşturma ve Yazdırma

**Kullanıcı Hikayesi:** Bir admin olarak her işlem sonrası fiş oluşturmak istiyorum; böylece müşteriye işlem kaydını fiziksel veya dijital olarak verebilirim.

#### Kabul Kriterleri

1. WHEN satış, alım veya para hareketi işlemi tamamlandığında, THE Platform SHALL otomatik olarak bir Fiş oluşturmalıdır.
2. THE Fiş SHALL işlem tarihi ve saati, müşteri adı, işlem türü, Fıstık_Cinsi (varsa), miktar (varsa), uygulanan Kur (varsa), toplam tutar ve güncel Kasa bakiyesi bilgilerini içermelidir.
3. THE Admin SHALL Fişi tarayıcı yazdırma diyaloğu aracılığıyla yazdırabilmelidir.
4. THE Admin SHALL Fişi PDF formatında indirebilmelidir.
5. THE Platform SHALL geçmiş Fişlere işlem kaydından erişim imkânı sağlamalıdır.

---

### Gereksinim 10: Gider Yönetimi

**Kullanıcı Hikayesi:** Bir admin olarak işletme giderlerini kayıt altına almak istiyorum; böylece nakliye, hammaliye ve fatura gibi maliyetleri takip edebileyim.

#### Kabul Kriterleri

1. THE Admin SHALL yeni gider kaydı oluşturabilmelidir; her gider için tarih, kategori, tutar ve açıklama bilgileri zorunludur.
2. THE Platform SHALL önceden tanımlı gider kategorilerini desteklemelidir: nakliye, hammaliye, fatura, kredi kartı ekstresi ve diğer.
3. THE Admin SHALL gider kaydına belge veya fotoğraf ekleyebilmelidir.
4. WHEN belge yüklendiğinde, THE Platform SHALL dosyayı Firebase Storage'a kaydetmeli ve gider kaydıyla ilişkilendirmelidir.
5. THE Admin SHALL yüklenen belgeyi görüntüleyebilmeli ve indirebilmelidir.
6. THE Admin SHALL mevcut gider kayıtlarını güncelleyebilmeli veya silebilmelidir.
7. THE Platform SHALL gider kayıtlarını tarih aralığı ve kategoriye göre filtreleyerek listeleyebilmelidir.

---

### Gereksinim 11: Raporlama

**Kullanıcı Hikayesi:** Bir admin olarak aylık ve dönemsel raporlar görmek istiyorum; böylece işletmenin genel durumunu ve müşteri bazlı hareketleri analiz edebileyim.

#### Kabul Kriterleri

1. THE Admin SHALL aylık müşteri bazlı rapor görüntüleyebilmelidir; rapor her müşteri için satılan fıstık miktarı, alınan fıstık miktarı, toplam satış tutarı ve dönem sonu Kasa bakiyesini içermelidir.
2. THE Admin SHALL belirli bir tarih aralığı için Kasa hareketlilik raporu görüntüleyebilmelidir; rapor tüm giriş ve çıkışları, toplam giriş tutarını ve toplam çıkış tutarını içermelidir.
3. THE Admin SHALL belirli bir tarih aralığı için gider raporu görüntüleyebilmelidir; rapor kategoriye göre gruplandırılmış toplam gider tutarlarını içermelidir.
4. THE Admin SHALL depo bazlı stok raporunu görüntüleyebilmelidir; rapor her depodaki Fıstık_Cinsi bazında mevcut stok miktarlarını içermelidir.
5. THE Admin SHALL raporları PDF formatında dışa aktarabilmelidir.

---

### Gereksinim 12: Müşteri Sayfası (Salt-Okunur Görünüm)

**Kullanıcı Hikayesi:** Bir müşteri olarak kendime özel linkten fıstık ve para durumumu görmek istiyorum; böylece depodaki fıstığımın ve kasadaki paramın güncel durumunu takip edebileyim.

#### Kabul Kriterleri

1. WHEN müşteri kendi Müşteri_Sayfası URL'sine eriştiğinde, THE Platform SHALL o müşteriye ait verileri göstermelidir: depodaki toplam Emanet_Fıstık miktarı (Fıstık_Cinsi bazında), satılan toplam fıstık miktarı ve güncel Kasa bakiyesi.
2. THE Müşteri_Sayfası SHALL son işlem hareketlerini kronolojik sırayla listelemelidir.
3. THE Müşteri_Sayfası SHALL herhangi bir veri değişikliği kontrolü veya formu içermemelidir.
4. THE Müşteri_Sayfası SHALL mobil cihazlarda düzgün görüntülenmelidir.
5. WHILE müşterinin Emanet_Fıstık miktarı sıfırsa ve Kasa bakiyesi sıfırsa, THE Müşteri_Sayfası SHALL "Aktif işlem bulunmamaktadır" mesajı göstermelidir.

---

### Gereksinim 13: Firebase Spark Plan Uyumluluğu

**Kullanıcı Hikayesi:** Bir admin olarak platformun ücretsiz Firebase katmanında çalışmasını istiyorum; böylece ek altyapı maliyeti olmadan sistemi kullanabilirim.

#### Kabul Kriterleri

1. THE Platform SHALL yalnızca Firebase Spark Plan kapsamındaki hizmetleri kullanmalıdır: Firestore, Authentication, Hosting ve Storage.
2. THE Platform SHALL Firestore okuma ve yazma işlemlerini minimize etmek için istemci tarafı önbellekleme uygulamalıdır.
3. THE Platform SHALL Storage'a yüklenen belgelerin boyutunu 5 MB ile sınırlandırmalıdır.
4. IF yüklenen dosya 5 MB sınırını aşıyorsa, THEN THE Platform SHALL yükleme işlemini engellemeli ve kullanıcıyı bilgilendirmelidir.
5. THE Platform SHALL Firestore güvenlik kurallarını; admin tam erişim, Müşteri_Sayfası token tabanlı salt-okunur erişim ve anonim erişim engeli şeklinde yapılandırmalıdır.

---

### Gereksinim 14: Veri Tutarlılığı ve Transaction Yönetimi

**Kullanıcı Hikayesi:** Bir admin olarak ilişkili veri güncellemelerinin tutarlı şekilde gerçekleşmesini istiyorum; böylece yarım kalan işlemler nedeniyle veri bozulması yaşanmasın.

#### Kabul Kriterleri

1. THE Platform SHALL Firestore transaction veya batch işlemleri kullanarak ilişkili veri güncellemelerini atomik olarak gerçekleştirmelidir.
2. IF transaction sırasında herhangi bir işlem başarısız olursa, THEN THE Platform SHALL tüm değişiklikleri geri almalıdır.
3. THE Platform SHALL satış, alım, stok transferi ve kasa işlemlerinde veri tutarlılığını korumalıdır.

---

### Gereksinim 15: Stok Hareket Yönetimi

**Kullanıcı Hikayesi:** Bir admin olarak tüm stok değişimlerinin kayıt altında tutulmasını istiyorum; böylece depo hareketlerini geriye dönük izleyebileyim.

#### Kabul Kriterleri

1. THE Platform SHALL tüm stok değişimlerini stock_movements kaydı olarak saklamalıdır.
2. THE stock_movements SHALL işlem türü, tarih, depo, müşteri, miktar ve Fıstık_Cinsi bilgilerini içermelidir.
3. THE Platform SHALL mevcut depo stoklarını stok hareketlerinden türetilmiş özet veri olarak tutabilmelidir.
4. THE Platform SHALL negatif depo stok oluşumunu engellemelidir.

---

### Gereksinim 16: Borç ve Negatif Bakiye Yönetimi

**Kullanıcı Hikayesi:** Bir admin olarak müşterilere borç para veya fıstık verebildiğimde bunları kayıt altına almak istiyorum; böylece borç durumunu takip edebileyim.

#### Kabul Kriterleri

1. THE Platform SHALL müşteri kasa bakiyesinin negatif olmasına izin verebilmelidir (borç para veya fıstık verildiğinde).
2. WHEN müşteri bakiyesi negatifse, THEN THE Platform SHALL müşteriyi "borçlu" olarak işaretlemelidir.
3. THE Platform SHALL borç durumunu raporlarda ayrı gösterebilmelidir.
4. THE Admin SHALL hem para hem de fıstık cinsinden borç kaydı oluşturabilmelidir.

---

### Gereksinim 17: İşlem Kur Sabitleme

**Kullanıcı Hikayesi:** Bir admin olarak geçmiş işlemlerin o anki Kur değeriyle kaydedilmesini istiyorum; böylece sonraki Kur değişimleri geçmiş işlemleri etkilemesin.

#### Kabul Kriterleri

1. THE Platform SHALL satış ve alım işlemlerinde kullanılan Kur değerini işlem anında kaydetmelidir.
2. THE Platform SHALL geçmiş işlemleri güncel Kur değişimlerinden etkilenmeyecek şekilde saklamalıdır.

---

### Gereksinim 18: Müşteri Sayfası Güvenliği

**Kullanıcı Hikayesi:** Bir admin olarak müşteri linklerinin güvenli olmasını ve gerektiğinde iptal edilebilmesini istiyorum; böylece yetkisiz erişimleri engelleyebileyim.

#### Kabul Kriterleri

1. THE Platform SHALL Müşteri_Sayfası URL tokenlarını en az 128-bit rastgele değer olarak üretmelidir.
2. THE Admin SHALL mevcut müşteri linkini iptal edip yeni link oluşturabilmelidir.
3. THE Platform SHALL eski müşteri linklerini geçersiz hale getirmelidir.
4. THE Platform SHALL müşteri erişim loglarını saklayabilmelidir.

---

### Gereksinim 19: Audit Log Sistemi

**Kullanıcı Hikayesi:** Bir admin olarak kritik veri değişikliklerinin kim tarafından ne zaman yapıldığını görmek istiyorum; böylece hesap verebilirliği sağlayabilirim.

#### Kabul Kriterleri

1. THE Platform SHALL kritik veri değişikliklerini audit_logs koleksiyonunda saklamalıdır.
2. THE audit_logs SHALL işlem yapan kullanıcı, işlem türü, eski değer, yeni değer ve tarih bilgilerini içermelidir.
3. THE Platform SHALL audit log kayıtlarının değiştirilmesini veya silinmesini engellemelidir.

---

### Gereksinim 20: Soft Delete Sistemi

**Kullanıcı Hikayesi:** Bir admin olarak silinen kayıtların tamamen yok edilmemesini istiyorum; böylece gerektiğinde geçmiş verilere erişebileyim.

#### Kabul Kriterleri

1. THE Platform SHALL müşteri, gider ve işlem kayıtlarında hard delete yerine soft delete kullanmalıdır.
2. THE Platform SHALL silinen kayıtları isDeleted alanıyla işaretlemelidir.
3. THE Platform SHALL silme tarihi ve silen kullanıcı bilgisini saklamalıdır.
4. THE Platform SHALL silinen kayıtları varsayılan listelerde göstermemelidir.

---

### Gereksinim 21: Performans ve Sayfalama

**Kullanıcı Hikayesi:** Bir admin olarak büyük veri setlerinde listeleme ekranlarının hızlı çalışmasını istiyorum; böylece yoğun kullanımda performans sorunu yaşanmasın.

#### Kabul Kriterleri

1. THE Platform SHALL listeleme ekranlarında pagination kullanmalıdır.
2. THE Platform SHALL büyük veri sorgularında limitli veri çekmelidir.
3. THE Platform SHALL raporlama ekranlarında özet veri koleksiyonları kullanabilmelidir.
4. THE Platform SHALL gereksiz Firestore okuma işlemlerini önlemek için istemci önbelleklemesi uygulamalıdır.

---

### Gereksinim 22: Özet Veri ve Cache Yönetimi

**Kullanıcı Hikayesi:** Bir admin olarak raporların hızlı yüklenmesini istiyorum; böylece her rapor açılışında tüm geçmiş veriler yeniden hesaplanmasın.

#### Kabul Kriterleri

1. THE Platform SHALL aylık rapor özetlerini ayrı koleksiyonlarda saklayabilmelidir.
2. THE Platform SHALL rapor oluştururken geçmiş hareketleri tekrar hesaplamak yerine özet verileri kullanabilmelidir.
3. THE Platform SHALL özet verileri işlem sonrası otomatik güncellemelidir.

---

### Gereksinim 23: Çevrimdışı Veri Senkronizasyonu

**Kullanıcı Hikayesi:** Bir admin olarak internet bağlantısı kesildiğinde de platformu kullanabilmek istiyorum; böylece bağlantı sorunları iş akışını durdurmasın.

#### Kabul Kriterleri

1. THE Platform SHALL Firestore offline persistence desteğini kullanabilmelidir.
2. WHEN aynı veri farklı cihazlarda değiştirilirse, THEN THE Platform SHALL son yazılan veriyi geçerli kabul etmelidir.
3. THE Platform SHALL senkronizasyon hatalarında kullanıcıyı bilgilendirmelidir.

---

### Gereksinim 24: İşlem İptal ve Ters Kayıt Sistemi

**Kullanıcı Hikayesi:** Bir admin olarak hatalı girilen işlemleri iptal edebilmek istiyorum; böylece veri bütünlüğünü bozmadan düzeltme yapabilirim.

#### Kabul Kriterleri

1. THE Admin SHALL satış, alım ve kasa işlemlerini iptal edebilmelidir.
2. THE Platform SHALL işlem iptalinde mevcut kaydı silmek yerine ters kayıt oluşturmalıdır.
3. THE Platform SHALL iptal edilen işlemleri raporlarda işaretlemelidir.
4. THE Platform SHALL iptal sebebi bilgisini saklamalıdır.

---

### Gereksinim 25: Rol Tabanlı Yetkilendirme

**Kullanıcı Hikayesi:** Bir admin olarak farklı çalışanlara farklı erişim seviyeleri tanımlamak istiyorum; böylece kritik işlemleri yalnızca yetkili kişiler yapabilsin.

#### Kabul Kriterleri

1. THE Platform SHALL farklı kullanıcı rolleri desteklemelidir: owner, employee ve readonly.
2. THE Platform SHALL her rol için farklı erişim izinleri uygulamalıdır.
3. THE Platform SHALL yalnızca owner rolüne kritik veri silme yetkisi vermelidir.

---

### Gereksinim 26: Veri Doğrulama ve Güvenlik Kuralları

**Kullanıcı Hikayesi:** Bir admin olarak istemciden gelen verilerin doğrulanmasını istiyorum; böylece yetkisiz veya hatalı veri değişiklikleri engellensin.

#### Kabul Kriterleri

1. THE Platform SHALL Firestore Security Rules ile koleksiyon bazlı erişim kontrolü uygulamalıdır.
2. THE Platform SHALL istemciden gelen veri alanlarını doğrulamalıdır.
3. THE Platform SHALL yetkisiz alan değişikliklerini engellemelidir.
4. THE Platform SHALL yalnızca izin verilen alanların güncellenmesine izin vermelidir.

---

### Gereksinim 27: Benzersiz İşlem ve Fiş Numarası

**Kullanıcı Hikayesi:** Bir admin olarak her işlemin ve fişin benzersiz bir numaraya sahip olmasını istiyorum; böylece işlemleri kolayca referans alabileyim.

#### Kabul Kriterleri

1. THE Platform SHALL her işlem için benzersiz işlem numarası üretmelidir.
2. THE Platform SHALL fişlerde benzersiz fiş numarası göstermelidir.
3. THE Platform SHALL işlem numaralarının tekrar etmesini engellemelidir.

---

### Gereksinim 28: Veri Yedekleme

**Kullanıcı Hikayesi:** Bir admin olarak verilerin düzenli yedeğini alabilmek istiyorum; böylece olası veri kayıplarına karşı güvende olayım.

#### Kabul Kriterleri

1. THE Platform SHALL verilerin düzenli dışa aktarımını desteklemelidir.
2. THE Admin SHALL JSON veya CSV formatında veri yedeği indirebilmelidir.
3. THE Platform SHALL yedekleme sırasında veri tutarlılığını korumalıdır.

---

### Gereksinim 29: Kasa Emaneti (Değerli Eşya Takibi)

**Kullanıcı Hikayesi:** Bir admin olarak müşteri veya akraba adına kasada saklanan döviz, altın gibi değerli eşyaları kayıt altına almak istiyorum; böylece kimin ne bıraktığını ve ne aldığını takip edebileyim.

#### Kabul Kriterleri

1. THE Admin SHALL kasa emaneti kaydı oluşturabilmelidir; her kayıt için emanet sahibi (mevcut müşteri veya yeni kişi), emanet türü (USD, EUR, TL, altın gram, diğer), miktar ve tarih bilgileri zorunludur.
2. THE Platform SHALL kasa emanetini fıstık ve para işlemlerinden bağımsız ayrı bir modül olarak yönetmelidir.
3. WHEN emanet girişi kaydedildiğinde, THE Platform SHALL emanet sahibinin toplam emanet bakiyesini güncellemelidir.
4. THE Admin SHALL emanet çıkışı (iade) kaydedebilmelidir; çıkış miktarı mevcut emanet bakiyesini aşamaz.
5. WHEN emanet iadesi yapıldığında, THE Platform SHALL Fiş oluşturmalıdır.
6. THE Platform SHALL tüm kasa emaneti hareketlerini (giriş/çıkış) tarih bazlı olarak listeleyebilmelidir.
7. THE Admin SHALL emanet sahibi bazında güncel bakiye özetini görüntüleyebilmelidir.
8. THE Platform SHALL farklı döviz cinslerini ve altını ayrı ayrı takip etmelidir (bakiyeler cins bazında tutulur).

---

### Gereksinim 30: Dinamik Fıstık Özellik Yönetimi

**Kullanıcı Hikayesi:** Bir admin olarak fıstık cinslerine istediğim özel özellikleri tanımlamak istiyorum; böylece iç rengi, 100 gramda iç gramaj, boz fıstık oranı, yaş gibi fiyatı etkileyen parametreleri sisteme kendim ekleyebileyim ve müşteri hesaplarında bu özellikler tablo halinde görünsün.

#### Kabul Kriterleri

1. THE Admin SHALL admin sayfasından global fıstık özellik şablonları tanımlayabilmelidir; her özellik için ad ve veri tipi (seçimli liste veya sayısal değer) belirlenmelidir.
2. THE Admin SHALL seçimli liste tipindeki özellikler için önceden tanımlı seçenekler ekleyebilmelidir (örn. iç rengi: "açık", "orta", "koyu").
3. WHEN admin bir müşteri hesabına fıstık girişi yaparken, THE Platform SHALL tanımlı tüm özellikleri kategori olarak göstermeli; seçimli olanlar için dropdown, sayısal olanlar için sayı giriş alanı sunmalıdır.
4. THE Platform SHALL özellik değerlerini ilgili fıstık partisiyle birlikte saklamalıdır.
5. THE Admin SHALL özellik şablonlarını güncelleyebilmeli veya silebilmelidir.
6. THE Admin SHALL özelliklerin fiyat hesaplamada çarpan veya düzeltici olarak kullanılıp kullanılmayacağını belirleyebilmelidir.
7. THE Müşteri_Sayfası SHALL fıstık partisine ait tüm özellik değerlerini tablo halinde salt-okunur olarak göstermelidir.
8. THE Platform SHALL müşterilerin özellik değerlerini değiştirmesine izin vermemelidir.
9. THE Platform SHALL özellik şablonu silindiğinde mevcut fıstık partilerindeki kayıtlı değerleri korumalıdır.
