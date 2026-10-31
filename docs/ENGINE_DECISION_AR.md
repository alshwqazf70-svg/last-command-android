# القرار التقني للمحرك — 31 أكتوبر 2026

## القرار
اعتماد **Godot 4.7.2 Stable** مع GDScript كنقطة انطلاق للنموذج الأول.

## لماذا؟
- المستخدم يعمل من هاتف Android ولا يعتمد على حاسوب محلي.
- نحتاج مسار بناء APK آلياً عبر GitHub Actions.
- Godot مفتوح المصدر ولا يتطلب تفعيل ترخيص محرك مدفوع في بيئة CI.
- توجد صورة بناء سحابية منشورة بإصدار محدد Godot 4.7.2، ومجهزة لتصدير Android.
- الإصدار 4.8 ما زال Beta في تاريخ القرار، لذلك نثبت على 4.7.2 المستقر ولا نستخدم إصداراً تجريبياً.

## لماذا لم نعتمد Unity الآن؟
Unity خيار قوي للرسومات ثلاثية الأبعاد، لكن مسار GameCI يتطلب إعداد ترخيص Unity وأسرار GitHub. هذا يزيد خطوات الإعداد على مستخدم يعمل من الهاتف فقط. يمكن إعادة تقييم Unity لاحقاً إذا ظهرت حاجة تقنية لا يغطيها Godot.

## حدود القرار
هذا قرار عملي للنموذج الأول وليس ادعاءً بأن Godot يتفوق على Unity في كل شيء. سنختبر:
1. نجاح تصدير APK من GitHub Actions.
2. التثبيت والتشغيل على Android 10.
3. الأداء والحرارة والذاكرة على Galaxy Note 9.
4. قابلية تنفيذ مشهد القاعدة والقتال ثلاثي الأبعاد.

إذا لم يحقق النموذج هذه المعايير، نراجع القرار قبل بناء أنظمة كبيرة.

## إعداد الرسومات الأولي
- Godot 4.7.2 Stable.
- GDScript.
- GL Compatibility في النموذج الأول لتوسيع التوافق مع الأجهزة.
- Landscape.
- هدف أولي 30 FPS ثابت على الجودة المتوسطة، ثم نقيس ونحسن.
- الأصول ثلاثية الأبعاد النهائية تُضاف لاحقاً بعد إثبات الأداء.

## مصادر القرار
- Godot Android export docs: https://docs.godotengine.org/en/latest/tutorials/export/exporting_for_android.html
- Godot stable archive: https://godotengine.org/download/archive/
- Godot CI image tags: https://hub.docker.com/r/barichello/godot-ci/tags
- GameCI Unity activation: https://game.ci/docs/github/activation/
