# إعدادات Flatsome — القيم الدقيقة

انسخ هذه القيم حقلاً بحقل. المسار: **Flatsome ← Theme Options**.

---

## 1) Style ← Colors

| الحقل | القيمة الجديدة | القيمة القديمة |
|-------|----------------|----------------|
| Primary Color | `#1A855B` | `#079616` |
| Secondary Color | `#C8801B` | `#252fea` ← أزرق كهربي متنافر |
| Success Color | `#1A855B` | `#079616` |
| Alert Color | `#C4372B` | `#f31010` |
| Base Color (text) | `#14211C` | `#000000` |
| Link Color | `#146B4A` | `#079616` |
| Link Hover | `#0B3D2C` | `#079616` |

**لماذا:** لون أساسي واحد للأفعال (الأزرار، الروابط) + لون تمييز دافئ للشارات والعروض. الأزرق الكهربي كان يتنافس مع الأخضر على نفس الوظيفة.

---

## 2) Style ← Typography

| الحقل | القيمة |
|-------|--------|
| Body Font | `Poppins` — Weight `400` |
| Body Font Size | `100%` ← (كانت 120%) |
| Headings Font | `Archivo` — Weight `800` |
| Headings Color | `#14211C` ← (كانت `#252fea`) |
| Nav Font | `Poppins` — Weight `600` |
| Text Transform (Headings) | `None` |

**لماذا:** خط مضغوط عريض للعناوين (Archivo) يعطي العناوين الضخمة حضورها، وخط هندسي واضح للنصوص (Poppins). العناوين الملوّنة بالأزرق كانت تقلّل قابلية القراءة.

> ملف `jannatan-modern.css` يضبط الخطوط بنفسه، فهذه الحقول احتياط في حال لم ترفع القالب الابن.

---

## 3) Layout

| الحقل | القيمة |
|-------|--------|
| Site Width | `1320` ← (كانت **530** وهي جذر مشكلة التخطيط) |
| Row Gutter | `20` |
| Site Layout | `Full Width` |
| Boxed | `Off` |

---

## 4) Header ← Header Main

| الحقل | القيمة |
|-------|--------|
| Height | `76` ← (كان 100) |
| Height Sticky | `68` |
| Height Mobile | `62` ← (كان 70) |
| Background Color | `#FFFFFF` (بلا شفافية) |
| Bottom Border | `1px #E4E8E5` |

### Header ← Logo
| الحقل | القيمة |
|-------|--------|
| Logo Width | `160` ← (كان 200) |
| Logo Height Mobile | `36` |

### Header ← Header Bottom
| الحقل | القيمة |
|-------|--------|
| Background | `#F2F9F5` ← (كان أزرق `#1e73be`) |
| Height | `46` |

### Header ← Elements (ترتيب العناصر)

**Desktop:**
- Left: `Logo`
- Center: `Search Form` ← اجعله بارزاً، فمتاجر المكمّلات تُتصفَّح بالبحث
- Right: `Main Menu` , `Account` , `Wishlist` , `Cart`

**Mobile:**
- Left: `Menu Icon (hamburger)`
- Center: `Logo`
- Right: `Cart`
- **Mobile Bottom Row:** `Search Form` (يظهر تحت الهيدر مباشرة)

### Header ← Sticky
- Sticky Header: `On` — `Shrink on scroll`

---

## 5) القائمة الرئيسية (هذه أهم خطوة — المتجر حالياً بلا قائمة)

المظهر ← القوائم ← أنشئ قائمة اسمها `Main Menu` وعيّنها لمكان `Main Menu`:

```
Shop            → /shop/  (قائمة منسدلة تحتها التصنيفات)
  ├── Immune Support
  ├── Heart Health
  ├── Sugar Support
  ├── Brain & Cognitive
  ├── Sleep
  ├── Gut Health
  ├── Hair, Skin & Nails
  └── Bone, Joint & Cartilage
Kids            → /product-category/kids/   (إن أنشأت التصنيف)
Bestsellers     → /shop/?orderby=popularity
Learn           → /blog/
About           → /about/
Contact         → /contact/
```

**لماذا:** الزائر حالياً يرى أيقونة قائمة فقط، ولا يعرف أن لديك 8 تصنيفات صحية. القائمة المنسدلة حسب «الهدف الصحي» (نوم، مناعة، قلب) هي أقوى طريقة تصفح في هذه الفئة.

---

## 6) Shop ← Product Catalog (صفحة التصنيفات)

| الحقل | القيمة |
|-------|--------|
| Products per row (Desktop) | `4` ← (كانت 3) |
| Products per row (Tablet) | `3` |
| Products per row (Mobile) | `2` ← (كانت **1**، وهذا أبطأ تصفح ممكن) |
| Products per page | `24` |
| Product Style | `Vertical` |
| Equal Height Boxes | `On` |
| Category Filter | `Sidebar (Off-canvas on mobile)` |
| Shop Page Title | `On` — مع Breadcrumbs |
| Product Hover | `Fade in` (خفيف) |

---

## 7) Shop ← Product Page (صفحة المنتج)

| الحقل | القيمة |
|-------|--------|
| Product Layout | `Default` |
| Sidebar | `Disabled` ← (لإخفاء «Recent Posts» من صفحة الشراء) |
| Gallery Style | `Slider with thumbnails on left` |
| Sticky Add to Cart | `On (Mobile only)` |
| Related Products | `4` |
| Up-sells | `On` |
| Product Zoom | `On` |
| Breadcrumbs | `On` |

---

## 8) Shop ← Cart & Checkout

| الحقل | القيمة |
|-------|--------|
| Cart Icon Style | `Basket` مع عدّاد |
| Add to Cart Action | `Open Cart Drawer (side)` ← لا تعيد تحميل الصفحة |
| Checkout Layout | `Two Column` |
| Distraction Free Checkout | `On` ← يخفي القائمة والفوتر أثناء الدفع (يرفع معدل إتمام الشراء) |
| Coupon Form | `Collapsed` |

---

## 9) Style ← Buttons

| الحقل | القيمة |
|-------|--------|
| Button Style | `Rounded` — نصف قطر `8px` (وليس Pill) |
| Button Text Transform | `None` ← (بدل UPPERCASE) |
| Primary Button Color | `#1A855B` |
| Secondary Button Color | `#C8801B` |

---

## 10) Performance

| الحقل | القيمة |
|-------|--------|
| Lazy Load Images | `On` |
| Preload Critical Assets | `On` |
| Disable unused Flatsome CSS | `On` |

---

## بعد الحفظ

أفرغ الكاش، وافتح الموقع في نافذة تصفح خفي. الفرق يجب أن يكون واضحاً فوراً في:
عرض الصفحة، ألوان الهيدر، شكل البطاقات، وعدد الأعمدة على الجوال.
