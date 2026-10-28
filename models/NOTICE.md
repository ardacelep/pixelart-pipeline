# models/ — lisans ve köken

Bu klasördeki `poz_modeli.pt`, deponun geri kalanından **farklı** lisanslıdır.

| ne | lisans | metin |
| --- | --- | --- |
| `poz_modeli.pt` | AGPL-3.0 | [LICENSE](LICENSE) |
| deponun kodu | MIT | [../LICENSE](../LICENSE) |

## Neden

`poz_modeli.pt` gövdesini [bizarre-pose-estimator](https://github.com/ShuhongChen/bizarre-pose-estimator)
projesinin illüstrasyon ön eğitimli ResNet50 ağırlıklarından alıyor
(`feat_concat_plusdata.safetensors`) ve o proje AGPL-3.0 lisanslı. Checkpoint
bu ağırlıklardan ince ayarla türetildi (künyede `on_egitimli: true`), bu
yüzden türetilmiş çalışma olarak aynı lisansla dağıtılıyor.

Kod Chen'in kodunu içermiyor ve ona bağlanmıyor: `pose_model.py` ağırlık
dosyasının `resnet.*` anahtarlarını torchvision `resnet50`'ye yüklüyor;
Detectron2 ya da Lightning gerekmiyor. Kod ile checkpoint bu yüzden ayrı
eserler olarak ayrı lisanslanıyor.

## Atıf

> Shuhong Chen, Matthias Zwicker. *Transfer Learning for Pose Estimation of
> Illustrated Characters.* WACV 2022, s. 793–802.
> [arXiv:2108.01819](https://arxiv.org/abs/2108.01819)

## Eğitim verisi

Eğitimde Chen'in poz veri seti (`bizarre_pose_dataset`, `chen_to_pixelart.py`
ile pikselleştirilmiş hali) de kullanıldı, ama veri seti **dağıtılmıyor**:
`_data/` gitignore'da.
