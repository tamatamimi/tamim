import '../models/category.dart';
import '../models/guide.dart';
import '../models/guide_type.dart';

/// Initial offline content. In production this is replaced by an import step
/// (bundled JSON, or a one-time sync from the institutional backend).
class SeedData {
  static const List<Category> categories = [
    Category(
        id: 1, nameAr: 'المالية', nameEn: 'Finance', icon: 'finance', sortOrder: 1),
    Category(
        id: 2,
        nameAr: 'المشتريات',
        nameEn: 'Procurement',
        icon: 'procurement',
        sortOrder: 2),
    Category(
        id: 3,
        nameAr: 'الموارد البشرية',
        nameEn: 'Human Resources',
        icon: 'hr',
        sortOrder: 3),
    Category(
        id: 4,
        nameAr: 'المخزون',
        nameEn: 'Inventory',
        icon: 'inventory',
        sortOrder: 4),
    Category(
        id: 5,
        nameAr: 'إدارة النظام',
        nameEn: 'System Administration',
        icon: 'settings',
        sortOrder: 5),
  ];

  static const List<Guide> guides = [
    Guide(
      id: 1,
      categoryId: 1,
      type: GuideType.written,
      titleAr: 'إنشاء قيد يومية',
      titleEn: 'Creating a Journal Entry',
      summaryAr: 'خطوات تسجيل قيد محاسبي يدوي في وحدة المالية.',
      summaryEn: 'Steps to record a manual journal entry in the Finance module.',
      contentAr: '''
## إنشاء قيد يومية

1. من القائمة الرئيسية اختر **المالية → دفتر اليومية**.
2. اضغط **قيد جديد**.
3. أدخل **التاريخ** و**المرجع**.
4. أضف سطور المدين والدائن حتى **يتوازن القيد** (إجمالي المدين = إجمالي الدائن).
5. أرفق المستند الداعم إن وجد.
6. اضغط **حفظ** ثم **ترحيل** للاعتماد.

> ملاحظة حوكمة: لا يمكن تعديل القيد بعد الترحيل — يُستخدم قيد عكسي بدلاً من ذلك.
''',
      contentEn: '''
## Creating a Journal Entry

1. From the main menu choose **Finance → General Journal**.
2. Click **New Entry**.
3. Enter the **date** and **reference**.
4. Add debit and credit lines until the entry is **balanced** (total debit = total credit).
5. Attach the supporting document if available.
6. Click **Save** then **Post** to commit.

> Governance note: a posted entry cannot be edited — use a reversing entry instead.
''',
      tags: ['محاسبة', 'قيد', 'journal', 'finance'],
      imageAsset: null,
      updatedAt: '2026-08-20',
    ),
    Guide(
      id: 2,
      categoryId: 2,
      type: GuideType.procedure,
      titleAr: 'دورة أمر الشراء (P2P)',
      titleEn: 'Purchase Order Cycle (P2P)',
      summaryAr: 'الإجراء المعتمد من الطلب حتى الاستلام والدفع.',
      summaryEn: 'Approved procedure from requisition to receipt and payment.',
      contentAr: '''
## دورة الشراء حتى الدفع

1. **طلب شراء** يقدّمه القسم المعني.
2. **اعتماد** حسب مصفوفة الصلاحيات.
3. تحويله إلى **أمر شراء** وإرساله للمورد.
4. **استلام البضاعة** وتسجيل محضر الاستلام.
5. **مطابقة ثلاثية**: أمر الشراء + الاستلام + فاتورة المورد.
6. **السداد** بعد المطابقة الناجحة.

**نقاط ضبط:** أي تباين في المطابقة الثلاثية يوقف السداد تلقائياً.
''',
      contentEn: '''
## Procure-to-Pay Cycle

1. **Purchase Requisition** raised by the requesting department.
2. **Approval** per the authority matrix.
3. Convert to **Purchase Order** and send to the vendor.
4. **Goods Receipt** and receipt note logged.
5. **Three-way match**: PO + Receipt + Vendor invoice.
6. **Payment** after a successful match.

**Control point:** any three-way-match variance blocks payment automatically.
''',
      tags: ['شراء', 'p2p', 'procurement', 'إجراءات'],
      imageAsset: null,
      updatedAt: '2026-08-22',
    ),
    Guide(
      id: 3,
      categoryId: 2,
      type: GuideType.dataFlow,
      titleAr: 'مخطط تدفق بيانات المشتريات',
      titleEn: 'Procurement Data Flow',
      summaryAr: 'تدفق البيانات بين الطلب والمورد والمالية والمخزون.',
      summaryEn: 'Data flow between requisition, vendor, finance, and inventory.',
      contentAr: '''
## مخطط تدفق البيانات — المشتريات

```
[القسم الطالب] --طلب شراء--> [نظام المشتريات]
      |                              |
      | اعتماد                       | أمر شراء
      v                              v
[مصفوفة الصلاحيات]            [المورد الخارجي]
                                     |
                              فاتورة/توريد
                                     v
[المخزون] <--إشعار استلام-- [المطابقة الثلاثية] --> [المالية/السداد]
```

تُخزَّن كل حركة في سجل تدقيق (Audit Trail) لأغراض الحوكمة والاعتماد.
''',
      contentEn: '''
## Data Flow Diagram — Procurement

```
[Requesting Dept] --requisition--> [Procurement System]
      |                                    |
      | approval                           | purchase order
      v                                    v
[Authority Matrix]                  [External Vendor]
                                           |
                                    invoice/delivery
                                           v
[Inventory] <--goods receipt-- [Three-way Match] --> [Finance/Payment]
```

Every movement is stored in an Audit Trail for governance and accreditation.
''',
      tags: ['dfd', 'تدفق', 'diagram', 'procurement'],
      imageAsset: null,
      updatedAt: '2026-08-25',
    ),
    Guide(
      id: 4,
      categoryId: 3,
      type: GuideType.useCase,
      titleAr: 'حالة استخدام: طلب إجازة',
      titleEn: 'Use Case: Leave Request',
      summaryAr: 'الأطراف والتدفق البديل لطلب إجازة موظف.',
      summaryEn: 'Actors and alternate flow for an employee leave request.',
      contentAr: '''
## حالة استخدام: طلب إجازة

- **الفاعل الأساسي:** الموظف
- **الفاعلون الثانويون:** المدير المباشر، الموارد البشرية
- **الشرط المسبق:** رصيد إجازات كافٍ

**التدفق الأساسي:**
1. يقدّم الموظف الطلب مع النوع والمدة.
2. يستلم المدير إشعاراً ويعتمد/يرفض.
3. عند الاعتماد يُخصم الرصيد ويُحدَّث التقويم.

**التدفق البديل:** رصيد غير كافٍ → يرفض النظام الطلب ويقترح إجازة بدون راتب.
''',
      contentEn: '''
## Use Case: Leave Request

- **Primary actor:** Employee
- **Secondary actors:** Line manager, HR
- **Precondition:** sufficient leave balance

**Main flow:**
1. Employee submits the request with type and duration.
2. Manager is notified and approves/rejects.
3. On approval the balance is deducted and the calendar updated.

**Alternate flow:** insufficient balance → system rejects and proposes unpaid leave.
''',
      tags: ['use case', 'إجازة', 'hr', 'موارد بشرية'],
      imageAsset: null,
      updatedAt: '2026-08-27',
    ),
    Guide(
      id: 5,
      categoryId: 4,
      type: GuideType.visual,
      titleAr: 'الجرد الدوري للمخزون (فيديو)',
      titleEn: 'Periodic Stock Count (Video)',
      summaryAr: 'شرح مرئي لخطوات الجرد الدوري والتسويات.',
      summaryEn: 'Visual walkthrough of the periodic count and adjustments.',
      contentAr: '''
## الجرد الدوري (دليل مرئي)

يوضّح هذا الدليل المرئي:

- تجميد حركة الأصناف قبل الجرد.
- إدخال الكميات الفعلية عبر الماسح.
- مراجعة **فروقات الجرد** واعتماد التسويات.

> أضف ملف الفيديو/الصور إلى `assets/images/` واربطه عبر الحقل `imageAsset`،
> أو ادمج مشغّل فيديو لاحقاً (video_player) لعرض المحتوى المرئي داخل التطبيق.
''',
      contentEn: '''
## Periodic Stock Count (Visual)

This visual guide covers:

- Freezing item movements before the count.
- Entering actual quantities via the scanner.
- Reviewing **count variances** and approving adjustments.

> Add the video/screenshots to `assets/images/` and link via the `imageAsset`
> field, or integrate a video player (video_player) later to play media in-app.
''',
      tags: ['جرد', 'مخزون', 'inventory', 'video'],
      imageAsset: null,
      updatedAt: '2026-08-29',
    ),
    Guide(
      id: 6,
      categoryId: 5,
      type: GuideType.procedure,
      titleAr: 'إدارة الصلاحيات والأدوار',
      titleEn: 'Roles & Permissions Management',
      summaryAr: 'إنشاء دور، ربط الصلاحيات، وإسناده للمستخدمين.',
      summaryEn: 'Create a role, bind permissions, assign it to users.',
      contentAr: '''
## إدارة الأدوار والصلاحيات

1. **إدارة النظام → الأدوار**.
2. أنشئ دوراً وامنحه الصلاحيات وفق مبدأ **الحد الأدنى من الامتياز**.
3. أسند الدور للمستخدمين (وليس صلاحيات فردية).
4. راجع الأدوار دورياً (Access Recertification) لأغراض الامتثال.

> فصل المهام (SoD): تجنّب منح صلاحيتَي الإنشاء والاعتماد لنفس المستخدم.
''',
      contentEn: '''
## Roles & Permissions

1. **System Administration → Roles**.
2. Create a role and grant permissions on a **least-privilege** basis.
3. Assign the role to users (not individual permissions).
4. Periodically review roles (access recertification) for compliance.

> Segregation of Duties (SoD): avoid granting both create and approve rights to the same user.
''',
      tags: ['صلاحيات', 'أدوار', 'security', 'admin'],
      imageAsset: null,
      updatedAt: '2026-09-01',
    ),
  ];
}
