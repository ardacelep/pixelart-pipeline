# Referans karakterler

Bu klasör iki işi birden yapıyor:

1. **Boru hattının örnek çıktısı** — her karakter araçlardan geçmiş,
   native çözünürlükte, gerçek alfa kanallı sprite sheet'ler.
2. **Poz modelinin holdout kümesi** — `ael`, `faküs`, `g1`, `mag` ile ölçüm
   yapılıyor. Bir karakter tümüyle eğitimden çıkarılıp o karakterdeki hata
   ölçülüyor; böylece ölçülen şey **görülmemiş çizim tarzına genelleme**
   oluyor. Rakamlar [README](../README.md#ölçüm-kaydı) içinde.

`faküs` en zor holdout: diğerlerinde 2.5-3.5 px olan hata orada 3.7-6.1 px'e
çıkıyor. Yani bir değişikliğin gerçekten işe yarayıp yaramadığı en net orada
görünüyor.

## Karakterler

| karakter | native kare | klip | sheet |
| --- | --- | --- | --- |
| `ael` | 87 px | 9 | 7 |
| `ardus` | 97 px | 3 | 2 |
| `faküs` | 91 px | 3 | 2 |
| `g1` | 86 px | 3 | 2 |
| `mag` | 85 px | 3 | 2 |
| `omerhan` | 88 px | 3 | 2 |

Native kare boyutları 85-97 px arasında ve **ölçeklenmiyor**. Pixel art'ta
yeniden ölçeklemek geri dönüşü olmayan bir kayıp; farklı boyutlar
`nativeFrameSize` ile taşınıyor ve oynatıcı tarafında tam sayı katlarıyla
büyütülüyor.

## meta.json

Üst düzeydeki her sözlük bir animasyon klibi:

```json
{
  "nativeFrameSize": 87,
  "idle":       {"file": "idle_spritesheet.png",       "frameSize": 87, "frameCount": 4, "frameDuration": 500},
  "walk_right": {"file": "walk_right_spritesheet.png", "frameSize": 87, "frameCount": 8, "frameDuration": 120},
  "walk_left":  {"file": "walk_right_spritesheet.png", "frameSize": 87, "frameCount": 8, "frameDuration": 120, "flip": true}
}
```

| alan | anlamı |
| --- | --- |
| `file` | Klibin sheet'i. Birden fazla klip aynı sheet'i paylaşabilir |
| `frameSize` | Kare kutusunun kenarı (kare); `nativeFrameSize` ile aynı olmalı |
| `frameCount` | Sheet'teki kare sayısı |
| `frameDuration` | Kare başına milisaniye |
| `flip` | Yatay aynala — sağa yürüyüşü sola çevirmek için |
| `yoyo` | Sona gelince geri sar; değer dönüş öncesi beklemesi (ms) |
| `reverse` | Kareleri tersten oynat (`otur` -> `kalk`) |
| `loop` | `false` ise bir kez oynar ve son karede durur |

`pixellab_karakter.py` ve `pack_sheet.py` bu bloğu zaten basıyor; elle
yazmak gerekmiyor.

> `displayName`, `lines` ve `walkSpeed` alanları bu araçların kullandığı
> alanlar değil; karakterler [desktop-pet](https://github.com/ardacelep/desktop-pet)
> için üretildiği için orada kaldılar.
