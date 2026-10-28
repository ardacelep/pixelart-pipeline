# pixelart-pipeline

Pixel art karakterler için iskelet (poz) tahmini ve animasyon üretimi üzerine
araç takımı: AI'nin ürettiği görselleri native çözünürlüğe indiren çıkarım
hattı, 18 eklemli bir poz modeli, iskeletten kukla kuran bir rig hattı ve
bunları besleyen veri seti derleyicileri.

Her araç tek başına çalışan bir CLI; hepsi `python3 tools/menu.py` ile tek
menüden de erişilebilir.

> Bu depo [desktop-pet](https://github.com/ardacelep/desktop-pet) içinde
> karakter üretmek için yazılan araçlardan ayrıldı. Pet uygulamasının kendisi
> (Electron, pencere yönetimi, davranış) o depoda kaldı; burada yalnızca
> pixel art tarafı var.

## Neden

AI modellerinden gelen "pixel art" doğrudan kullanılamaz. Dosya 1024×1024
gelir ama içindeki gerçek pixel art 100×100'dür — her sanal piksel ~10.24
gerçek piksellik bir blok. Üstelik şeffaflık gerçek değildir: arka plana dama
deseni **çizilmiştir**. Animasyon istediğinizde her kare ayrı bir üretim
olduğu için kareler birbirine göre kayıktır ve yan yana dizilince karakter
titrer.

Bu deponun yaptığı iş, bu kusurların her birini **ölçüp** düzeltmek. Kararların
çoğu ölçümle alındı ve gerekçeleri araçların kendi docstring'lerinde duruyor;
hangi kısıtın gerçekten kritik olduğu [PROMPTS.md](PROMPTS.md) içinde ayrı
ayrı ayrılmış durumda.

## Kurulum

Çekirdek araçlar yalnızca iki paket istiyor:

```bash
pip3 install -r requirements.txt
```

Poz modelini eğitmek/çalıştırmak isterseniz torch gerekiyor:

```bash
pip3 install -r requirements-model.txt
```

Bu şart değil: araçlar `torch`'u tembel import eder ve yoksa sezgisel
iskelete düşer. Hazır bir ComfyUI ortamınız varsa en kolayı onu kullanmak:

```bash
~/ComfyUI/venv/bin/python tools/pose_model.py eval _data/karisik_yan --ckpt models/poz_modeli.pt
```

PixelLab araçları ücretli bir API kullanıyor. Anahtarı `.env` içine koyun:

```bash
cp .env.example .env     # sonra PIXELLAB_API_KEY= satırını doldurun
```

Model dosyası Git LFS'te. `git lfs install` yapılmadan klonlandıysa
`models/poz_modeli.pt` birkaç yüz baytlık bir işaretçi olarak gelir —
araçlar bunu fark edip uyarır:

```bash
git lfs install && git lfs pull
```

## Hızlı başlangıç

```bash
python3 tools/menu.py
```

Menü her adımda çalıştırdığı komutu da ekrana basar, yani CLI'ı öğrenmenin
kısa yolu olarak da kullanılabilir.

## Depo düzeni

```
tools/              31 CLI aracı + 11 regresyon testi (düz modül düzeni)
characters/         referans karakterler — hem örnek çıktı hem poz modelinin
                    holdout kümesi (ael, faküs, g1, mag, omerhan, ardus)
models/             yayınlanmış üretim modeli (LFS)
_data/              eğitim verisi ve checkpoint'ler — gitignore'da, makineye özel
PROMPTS.md          Gemini prompt rehberi: hangi kısıt kritik, hangisi değil
```

`tools/` düz bir modül düzeni: araçlar birbirini doğrudan import eder
(`import skeleton as sk`) ve yolları depo kökünden çözer. Yani `tools/`
içinden değil, **depo kökünden** çalıştırın.

## Boru hattı

Karakter üretmenin üç yolu var; üçü de aynı iskelet/sheet biçiminde buluşuyor.

### 1. Gemini çıktısını işleme

```bash
python3 tools/pixelart_extract.py sheet_ham.png sheet_native.png
python3 tools/split_sheet.py sheet_native.png -o kareler/ --frames 7 --preview bolme.png
python3 tools/pack_sheet.py kareler/kare_*.png -o walk_right_spritesheet.png --gif onizleme.gif
```

**Bu sıra önemli.** Sezgisel olan sıra (önce böl, sonra her kareyi ayrı çıkar)
yanlış: ızgara tespiti her kare için bağımsız çalışır ve bir kare 100×100,
diğeri 97×97 tespit edilebilir. O noktada kareler farklı piksel ölçeğinde olur
ve düzeltmenin tek yolu ölçeklemektir — yani pixel art'ı bozmaktır. Izgara
sheet'in tamamında tek bir kafestir; bir kez ölçülünce tüm kareler garantili
aynı ölçekte çıkar.

`--verify` çıkarımın kayıpsızlığını ölçer: ızgara gerçekten oturuyor mu, her
hücreye tek renk atanabiliyor mu, bir hücrede *gerçekten* iki renk çarpışıyor
mu, kaynağın gürültü tabanı ne. Üçüncüsü gerçek detay kaybının tek olası
kaynağı; 0 çıkması çıkarımın kaynağın izin verdiği ölçüde birebir olduğu
anlamına gelir.

### 2. PixelLab ile üretme (ücretli)

```bash
python3 tools/pixellab_karakter.py kedi.png --ad kedi --dry-run   # sadece maliyet
python3 tools/pixellab_karakter.py kedi.png --ad kedi
```

Tek bir önden bakan PNG'den idle + walk klipleri ve `meta.json` üretir. Ödenmiş
her adım `_data/pixellab/<ad>/durum.json`'a yazılır; araç tekrar çalıştırılınca
kaldığı yerden devam eder, aynı adım iki kez ödenmez.

### 3. Kukla + diffusion

```bash
python3 tools/iskelet_rig.py characters/ael/walk_right_spritesheet.png \
    --sablon _data/sablonlar.json --klip walk_right -o _cikti/ael
python3 tools/kukla_kontrol.py _cikti/ael --tip lineart -o _cikti/ael/kontrol
python3 tools/comfy_uret.py --referans characters/ael/walk_right_spritesheet.png -o _cikti/kare0
```

İskeletten kukla (cutout rig) türetir, pozlar, ControlNet kontrol görüntüsüne
çevirir ve ComfyUI'da temize çekip native çözünürlüğe indirir.

## İskelet ve poz modeli

İskelet 18 eklem: `NOSE NECK R/L SHOULDER ELBOW ARM HIP KNEE LEG R/L EYE EAR`.

İki tahminci var:

| | nasıl | görülmemiş karakterde |
| --- | --- | --- |
| `skeleton.py` | sezgisel — silüet, medial eksen, renk işaretleri | 13.46 px |
| `pose_model.py` | SimCC başlıklı ResNet50, dedektörsüz | 3.05–4.01 px |

Sezgisel algoritmanın kendi ayarlandığı karakterlerde 2 px'e indiği ölçüldü,
ama o sayı yanıltıcı: adil ölçüm (karakteri tümüyle eğitimden çıkarmak) model
lehine yaklaşık dört kat fark veriyor. Bu yüzden `skeleton_edit.py` model
varsa onu kullanır, yoksa sezgisele düşer.

### Tasarım kararları

- **Dedektör yok.** Tuvalde tek karakter var ve ortalı. PixelLab'e iki karakter
  yan yana verildiğinde tek iskelet döndürüp onu ikisine yaydığı ölçüldü.
  DWPose'un bu veride hiç ateşlememesinin sebebi tam da dedektör aşaması.
- **Isı haritası değil, SimCC.** Isı haritası tipik olarak 1/4 çözünürlükte
  üretilir; 128×128 girdide bu 32×32, yani 4 piksel yuvarlama — biz 2 piksel
  arıyoruz. SimCC x ve y'yi ayrı ayrı bin'lere sınıflandırdığı için alt-piksel
  çözünürlük veriyor.
- **Gövde: illüstrasyon ön eğitimli ResNet50.** Ön eğitim alanı mimariden daha
  belirleyici çıktı; ImageNet ön eğitimine göre %10-20 PDJ farkı ölçülmüş.
- **Bölme karakter bazında.** Rastgele bölme aynı karakterin artırılmış
  kopyalarını hem eğitime hem teste koyar ve sahte yüksek skor üretir.

### Ölçüm kaydı

Her satır, o karakter **tümüyle eğitimden çıkarılarak** ölçülen hata (piksel,
128×128 tuval). Tek holdout gürültülü olduğu için dört holdout ortalaması
alınıyor.

| deney | veri | faküs | mag | ael | g1 | **ort** |
| --- | --- | --- | --- | --- | --- | --- |
| m195 | 195 üretilen, Chen yok | 6.05 | 2.91 | 4.13 | 2.97 | **4.01** |
| mchen | + 2092 Chen illüstrasyon | 5.06 | 2.83 | 3.83 | 2.83 | **3.64** |
| myan69 | + yandan bakan karakterler | 3.85 | 2.60 | 3.56 | 2.72 | **3.18** |
| sa | aynı veri, varyant | 3.70 | 2.76 | 3.56 | 2.88 | **3.23** |
| mbl | + Blender render'ları | 3.69 | 2.46 | 3.38 | 2.65 | **3.05** |
| bl2 | + ikinci Blender partisi | 4.05 | 2.61 | 3.53 | 2.74 | **3.23** |

Okunacak iki şey var. **Önden/yandan farkı asıl sorundu**: `mchen` kırılımında
önden (idle) ortalama 1.51 px, yandan (walk) 4.06 px — çünkü 195 üretilen
karakterin tamamı öndendi. `pixellab_dondur.py` tam bu yüzden var ve `myan69`
kazancı oradan geliyor. **İkinci Blender partisi kaybettirdi**: 4/4 holdout'ta
3.05 → 3.23. Veri eklemek tek yönlü bir iyileştirme değil.

Üretim modeli (`models/poz_modeli.pt`) holdout'suz, yani tüm karakterlerle
eğitilmiş: 4363 örnek, 7 karakter, 16 epok. Künye checkpoint'in içinde:

```bash
~/ComfyUI/venv/bin/python tools/pose_model.py eval _data/karisik_yan --ckpt models/poz_modeli.pt
```

### Elle etiketleme

```bash
python3 tools/skeleton_edit.py
```

Sprite'ı sürükleyin, iskelet otomatik çıkar, elle düzeltin. Tahminler model
varsa modelden gelir, böylece iş düzeltmeye indirgenir.

## Araç dizini

**Pixel art çıkarımı ve sheet işleme**

| araç | ne yapar |
| --- | --- |
| `pixelart_extract.py` | "Büyütülmüş" AI pixel art'ını native çözünürlüğe indirir, dama desenini gerçek alfaya çevirir |
| `split_sheet.py` | Sprite sheet'i tek tek karelere böler (1×N, N×1, R×C) |
| `pack_sheet.py` | Ayrı çıkarılmış kareleri içeriğe göre hizalayıp tek sheet'te paketler |
| `iki_gorunus.py` | İki görünüşlü çıktıyı önden + yandan kareye ayırır |
| `palette_reduce.py` | AI'nin şişirdiği renk paletini gerçek pixel art seviyesine indirir |
| `grid_ref.py` | Bitmiş sheet'i prompt'a verilecek ızgara referansına çevirir |

**İskelet ve poz**

| araç | ne yapar |
| --- | --- |
| `skeleton.py` | Karakter karesinden sezgisel iskelet çıkarır |
| `skeleton_edit.py` | Etiketleme arayüzü: otomatik çıkar, elle düzelt |
| `pose_model.py` | Poz modeli — eğitim ve eval (SimCC başlığı) |
| `pose_dataset.py` | Poz modeli için etiketli veri toplar |
| `medial.py` | Silüetin medial ekseni ve üzerinde yol bulma |
| `poz_referans.py` | İskelet poz referans sheet'i üretir (prompt için) |
| `poz_sablonu.py` | Animasyon poz dizilerini kemik açısı olarak tutar |
| `model_yayinla.py` | Üretim modelini depoya konabilecek hale getirir |

**Kukla (rig) ve animasyon üretimi**

| araç | ne yapar |
| --- | --- |
| `iskelet_rig.py` | İskeletten kukla ve poz dosyası türetir |
| `rig_pose.py` | Tek kareden kukla kurup yeni pozlar üretir |
| `kukla_kontrol.py` | Kukla karelerini ControlNet kontrol görüntüsüne çevirir |
| `comfy_uret.py` | Kuklayı ComfyUI'da temize çekip pixel art'a indirger |
| `onarim_veri.py` | (bozuk kukla → temiz kare) eğitim çiftleri üretir |

**PixelLab API (ücretli)**

| araç | ne yapar |
| --- | --- |
| `pixellab_karakter.py` | Tek görselden animasyonlu karakter üretir |
| `pixellab_animasyon.py` | Mevcut karaktere yeni animasyon klibi ekler |
| `pixellab_generate.py` | Poz modeli için çeşitli karakterler ürettirir |
| `pixellab_dondur.py` | Önden karakterleri yandan hale çevirip etiketler |
| `pixellab_etiketle.py` | Bir klasörü `estimate-skeleton` ile etiketler |

**Veri seti derleyicileri**

| araç | ne yapar |
| --- | --- |
| `chen_to_pixelart.py` | Chen illüstrasyon poz veri setini pixel art'a çevirir |
| `lpc_derle.py` | LPC katmanlarından karakter üretir ve karelere ayırır |
| `blender_veri.py` | Blender içinde çalışır; 3B sahneden 18 noktalı poz verisi çıkarır |
| `blender_to_pixelart.py` | Blender render'larını eğitim kümesi biçimine çevirir |
| `veri_birlestir.py` | Birden fazla veri setini tek eğitim kümesinde birleştirir |
| `veri_onizle.py` | Eğitim veri setini iskeletleriyle birlikte göze getirir |

## _data/ — eğitim verisi

`.gitignore` içinde ve öyle kalmalı: gigabaytlarca görsel, ve üretim maliyeti
PixelLab bakiyesi. Yani bu klasör **makineye özel**; başka bir makinede
yeniden üretmek/eğitmek gerekir. Asıl korunması gereken `_data/uretim*` ve
`_data/poz` — onlar ödenmiş üretim. Checkpoint künyeleri ve deney kaydı
`_data/modeller/OKU.md` içinde.

## Testler

```bash
python3 tools/menu.py        # -> "Araç testlerini çalıştır"
```

ya da doğrudan:

```bash
for t in pixelart_extract split_sheet pack_sheet grid_ref skeleton pose_dataset \
         veri_kapilari pixellab_karakter iki_gorunus skeleton_edit iskelet_rig; do
  python3 "tools/test_$t.py" || echo "FAIL $t"
done
```

11 regresyon testi; ağa çıkmaz, kendi fixture'larını üretir, `_data/`
gerektirmez.

## Lisans ve üçüncü parti

- **Kod: MIT** — [LICENSE](LICENSE).
- **`models/poz_modeli.pt`: AGPL-3.0** — gövdesi
  [bizarre-pose-estimator](https://github.com/ShuhongChen/bizarre-pose-estimator)
  projesinin AGPL-3.0 lisanslı illüstrasyon ön eğitimli ağırlıklarından
  türetildi. Gerekçe ve atıf: [models/NOTICE.md](models/NOTICE.md).
- LPC taban gövdelerinin hiçbiri CC0 değil (CC-BY-SA 3.0 / GPL 3.0 / OGA-BY 3.0,
  çoklu ve "veya"); katmanların yalnızca %8'i CC0 ve legs/feet'te hiç yok.
  `lpc_derle.py --lisans` ile süzülüyor ve kullanılan her katmanın künyesi
  çıktı klasörüne yazılıyor. LPC verisi `_data/` altında, dağıtılmıyor.
- PixelLab çağrıları ücretli ve kendi şartlarına tabi.
