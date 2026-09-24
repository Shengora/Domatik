# Voice Assistant (Ovozli Yordamchi) MVP

Bu dastur Flutter va Native Android (Kotlin) da yozilgan bo'lib, telefonni ovoz orqali boshqarish imkonini beradi.

## Xususiyatlar
- Mikrofon orqali ovozli buyruqlarni qabul qilish.
- **Ilovalarni ochish**: "Telegram och", "open Chrome", "открой YouTube" va hk.
- **Qo'ng'iroq qilish**: "Akmalga qo'ng'iroq qil" kabi buyruqlar va tasdiqlash dialogi.
- **Surish (Swipe)**: Ekran bo'ylab tepaga yoki pastga surish ("pastga sur", "tepaga sur", "10 ta sur").
- Uch xil tillarni qo'llab-quvvatlaydi (O'zbek, Rus, Ingliz) va u orqali lokalizatsiya qilingan (Flutter l10n).
- Barcha ruxsatlarni Onboarding ekranida avtomatik so'raydi.

## Ilovani ishga tushirish (Android)
1. Flutter o'rnatilganligiga ishonch hosil qiling va telefoningiz kompyuterga ulangan bo'lishi kerak.
2. Terminalda papkaga kirib quyidagi buyruqni bering:
   ```bash
   flutter pub get
   flutter gen-l10n
   flutter run
   ```

## Accessibility xizmatini yoqish (Maxsus imkoniyatlar)
Ushbu ilova ovoz orqali ekranni surish (swipe) kabi funksiyalarni amalga oshirish uchun Android'ning "Accessibility" (Maxsus imkoniyatlar) xizmatidan foydalanadi.

1. Ilovani birinchi marta ochganingizda ruxsatlar oynasi chiqadi.
2. **"Maxsus Imkoniyatlar" (Accessibility)** yonidagi **"Sozlamalarni ochish"** tugmasini bosing.
3. Telefoningizning maxsus imkoniyatlar (Accessibility) menyusi ochiladi.
4. Ro'yxatdan **"voice_assistant"** (yoki VoiceAssistant) degan joyni toping va uni faollashtiring (Yoqish / On).
5. Ilovaga qayting, barcha ruxsatlar tekshirilib davom etishga ruxsat beriladi.
