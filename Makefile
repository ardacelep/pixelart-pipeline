# npm script kisayollarinin yerine. Hepsi depo kokunden calisir.
PY ?= python3
TESTLER = pixelart_extract split_sheet pack_sheet grid_ref skeleton \
          pose_dataset veri_kapilari pixellab_karakter iki_gorunus \
          skeleton_edit iskelet_rig

.PHONY: kur kur-model menu skeleton etiketle onizle karakter test

kur:
	$(PY) -m pip install -r requirements.txt

kur-model:
	$(PY) -m pip install -r requirements-model.txt

menu:
	$(PY) tools/menu.py

skeleton:
	$(PY) tools/skeleton_edit.py

etiketle:
	$(PY) tools/skeleton_edit.py --klasor _data/lpc_etiket/gorseller

onizle:
	$(PY) tools/veri_onizle.py

karakter:
	$(PY) tools/pixellab_karakter.py

test:
	@fail=0; for t in $(TESTLER); do \
	  $(PY) tools/test_$$t.py >/dev/null 2>&1 \
	    && echo "  ok   $$t" \
	    || { echo "  FAIL $$t"; fail=1; }; \
	done; exit $$fail
