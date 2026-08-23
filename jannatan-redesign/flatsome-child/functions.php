<?php
/**
 * Jannatan Naturals — Flatsome Child Theme
 *
 * كل التحسينات هنا مبنية على hooks فقط، بدون تعديل ملفات القالب الأصلي،
 * وكل دالة محمية بفحص وجود WooCommerce حتى لا يتعطل الموقع.
 *
 * @package jannatan
 */

defined( 'ABSPATH' ) || exit;

define( 'JANNATAN_VERSION', '2.2.2' );

/* -------------------------------------------------------------------------
 * 1) تحميل الأنماط والسكربتات
 * ---------------------------------------------------------------------- */
function jannatan_enqueue_assets() {

	// الخطوط (احذف هذا السطر إن رفعت الخطوط محلياً — أسرع وأفضل للخصوصية).
	wp_enqueue_style(
		'jannatan-fonts',
		'https://fonts.googleapis.com/css2?family=Archivo:wdth,wght@62.5..125,400..900&family=Poppins:wght@400;500;600;700&family=Tajawal:wght@400;500;700;800;900&display=swap',
		array(),
		null
	);

	// نظام التصميم — يُحمّل بعد ستايل Flatsome الأساسي.
	wp_enqueue_style(
		'jannatan-ui',
		get_stylesheet_directory_uri() . '/assets/css/jannatan-modern.css',
		array( 'flatsome-main' ),
		JANNATAN_VERSION
	);

	wp_enqueue_script(
		'jannatan-ui',
		get_stylesheet_directory_uri() . '/assets/js/jannatan-ui.js',
		array(),
		JANNATAN_VERSION,
		true
	);

	wp_localize_script(
		'jannatan-ui',
		'jannatanUI',
		array(
			'isProduct'   => function_exists( 'is_product' ) && is_product(),
			'addToCartTx' => __( 'Add to cart', 'jannatan' ),
		)
	);
}
add_action( 'wp_enqueue_scripts', 'jannatan_enqueue_assets', 20 );

/* -------------------------------------------------------------------------
 * 2) كلاسات الـ body
 * ---------------------------------------------------------------------- */
function jannatan_body_classes( $classes ) {
	$classes[] = 'jn-has-bottom-nav';
	if ( function_exists( 'is_product' ) && is_product() ) {
		$classes[] = 'jn-pdp';
	}
	return $classes;
}
add_filter( 'body_class', 'jannatan_body_classes' );

/* -------------------------------------------------------------------------
 * 3) شريط التنقل السفلي للجوال
 *    (الرئيسية / المتجر / البحث / السلة / حسابي)
 * ---------------------------------------------------------------------- */
function jannatan_mobile_bottom_nav() {

	if ( ! function_exists( 'wc_get_cart_url' ) ) {
		return;
	}

	$count     = WC()->cart ? WC()->cart->get_cart_contents_count() : 0;
	$shop_url  = function_exists( 'wc_get_page_permalink' ) ? wc_get_page_permalink( 'shop' ) : home_url( '/shop/' );
	$acct_url  = function_exists( 'wc_get_page_permalink' ) ? wc_get_page_permalink( 'myaccount' ) : home_url( '/my-account/' );

	$items = array(
		array( 'url' => home_url( '/' ), 'icon' => '⌂',  'label' => __( 'Home', 'jannatan' ),   'active' => is_front_page() ),
		array( 'url' => $shop_url,       'icon' => '▤',  'label' => __( 'Shop', 'jannatan' ),   'active' => ( function_exists( 'is_shop' ) && ( is_shop() || is_product_category() ) ) ),
		array( 'url' => '#',             'icon' => '⌕',  'label' => __( 'Search', 'jannatan' ), 'active' => false, 'attr' => ' data-jn-search="1"' ),
		array( 'url' => wc_get_cart_url(), 'icon' => '⛿', 'label' => __( 'Cart', 'jannatan' ),  'active' => ( function_exists( 'is_cart' ) && is_cart() ), 'count' => $count ),
		array( 'url' => $acct_url,       'icon' => '☺',  'label' => __( 'Account', 'jannatan' ), 'active' => ( function_exists( 'is_account_page' ) && is_account_page() ) ),
	);

	echo '<nav class="jn-bottom-nav" aria-label="' . esc_attr__( 'Mobile navigation', 'jannatan' ) . '"><ul>';
	foreach ( $items as $item ) {
		$attr  = isset( $item['attr'] ) ? $item['attr'] : '';
		$class = ! empty( $item['active'] ) ? ' is-active' : '';
		echo '<li><a class="jn-bn-link' . esc_attr( $class ) . '" href="' . esc_url( $item['url'] ) . '"' . $attr . '>';
		echo '<span class="jn-ico" aria-hidden="true">' . esc_html( $item['icon'] ) . '</span>';
		if ( ! empty( $item['count'] ) ) {
			echo '<span class="jn-cart-count jn-cart-count-js">' . esc_html( $item['count'] ) . '</span>';
		}
		echo '<span>' . esc_html( $item['label'] ) . '</span>';
		echo '</a></li>';
	}
	echo '</ul></nav>';
}
add_action( 'wp_footer', 'jannatan_mobile_bottom_nav', 30 );

/* تحديث عدّاد السلة عبر AJAX بدون إعادة تحميل الصفحة */
function jannatan_cart_count_fragment( $fragments ) {
	$count = WC()->cart ? WC()->cart->get_cart_contents_count() : 0;
	$fragments['.jn-cart-count-js'] = '<span class="jn-cart-count jn-cart-count-js">' . esc_html( $count ) . '</span>';
	return $fragments;
}
add_filter( 'woocommerce_add_to_cart_fragments', 'jannatan_cart_count_fragment' );

/* -------------------------------------------------------------------------
 * 4) صفحة المنتج: شارات الثقة تحت زر الشراء
 * ---------------------------------------------------------------------- */
function jannatan_pdp_trust_badges() {
	$badges = array(
		'✓ ' . __( 'Third-party tested', 'jannatan' ),
		'✓ ' . __( 'Non-GMO & gluten free', 'jannatan' ),
		'⇆ ' . __( '30-day money back', 'jannatan' ),
		'⚡ ' . __( 'Ships within 24h', 'jannatan' ),
	);

	echo '<div class="jn-pdp-trust">';
	foreach ( $badges as $badge ) {
		echo '<div>' . esc_html( $badge ) . '</div>';
	}
	echo '</div>';
}
add_action( 'woocommerce_after_add_to_cart_form', 'jannatan_pdp_trust_badges', 15 );

/* -------------------------------------------------------------------------
 * 5) شريط "أضف إلى السلة" الثابت على الجوال
 * ---------------------------------------------------------------------- */
function jannatan_sticky_add_to_cart() {

	if ( ! function_exists( 'is_product' ) || ! is_product() ) {
		return;
	}

	global $product;
	if ( ! is_object( $product ) ) {
		return;
	}

	echo '<div class="jn-sticky-atc" aria-hidden="false">';
	echo '<div class="jn-sticky-atc__info">';
	echo '<div class="jn-sticky-atc__name">' . esc_html( $product->get_name() ) . '</div>';
	echo '<div class="jn-sticky-atc__price">' . wp_kses_post( $product->get_price_html() ) . '</div>';
	echo '</div>';
	echo '<a href="#" class="button primary jn-sticky-atc__btn">' . esc_html__( 'Add to cart', 'jannatan' ) . '</a>';
	echo '</div>';
}
add_action( 'wp_footer', 'jannatan_sticky_add_to_cart', 20 );

/* -------------------------------------------------------------------------
 * 6) السلة: مؤشّر التقدّم نحو الشحن المجاني
 *    عدّل قيمة الحد من الفلتر jannatan_free_shipping_threshold
 * ---------------------------------------------------------------------- */
function jannatan_free_shipping_progress() {

	if ( ! function_exists( 'WC' ) || ! WC()->cart ) {
		return;
	}

	$threshold = (float) apply_filters( 'jannatan_free_shipping_threshold', 50 );
	if ( $threshold <= 0 ) {
		return;
	}

	$subtotal  = (float) WC()->cart->get_displayed_subtotal();
	$remaining = max( 0, $threshold - $subtotal );
	$percent   = min( 100, ( $subtotal / $threshold ) * 100 );

	echo '<div class="jn-freeship">';
	if ( $remaining > 0 ) {
		printf(
			/* translators: %s: remaining amount */
			esc_html__( 'You are %s away from free shipping', 'jannatan' ),
			wp_kses_post( '<strong>' . wc_price( $remaining ) . '</strong>' )
		);
	} else {
		echo '<strong>' . esc_html__( 'Great — you unlocked free shipping!', 'jannatan' ) . '</strong>';
	}
	echo '<div class="jn-freeship__bar"><div class="jn-freeship__fill" style="width:' . esc_attr( $percent ) . '%"></div></div>';
	echo '</div>';
}
add_action( 'woocommerce_before_cart_table', 'jannatan_free_shipping_progress', 5 );
add_action( 'woocommerce_before_checkout_form', 'jannatan_free_shipping_progress', 5 );

/* -------------------------------------------------------------------------
 * 7) تنظيف صفحة المنتج: إزالة سايدبار المدونة
 * ---------------------------------------------------------------------- */
function jannatan_remove_product_sidebar() {
	if ( function_exists( 'is_product' ) && is_product() ) {
		remove_action( 'woocommerce_sidebar', 'woocommerce_get_sidebar', 10 );
	}
}
add_action( 'wp', 'jannatan_remove_product_sidebar' );

/* -------------------------------------------------------------------------
 * 8) المنتجات ذات الصلة: 4 فقط وبصف واحد
 * ---------------------------------------------------------------------- */
function jannatan_related_products_args( $args ) {
	$args['posts_per_page'] = 4;
	$args['columns']        = 4;
	return $args;
}
add_filter( 'woocommerce_output_related_products_args', 'jannatan_related_products_args', 20 );

/* -------------------------------------------------------------------------
 * 9) نص أوضح لزر المنتجات التي لا تُشترى مباشرة
 *    ("Read more" غامض — يوحي بمقال لا بمنتج)
 * ---------------------------------------------------------------------- */
function jannatan_loop_button_text( $text, $product ) {
	if ( ! $product instanceof WC_Product ) {
		return $text;
	}
	if ( ! $product->is_purchasable() || ! $product->is_in_stock() ) {
		return __( 'View details', 'jannatan' );
	}
	return $text;
}
add_filter( 'woocommerce_product_add_to_cart_text', 'jannatan_loop_button_text', 20, 2 );

/* -------------------------------------------------------------------------
 * 10) عرض اسم التصنيف فوق اسم المنتج في البطاقة (يساعد على الفهم السريع)
 * ---------------------------------------------------------------------- */
function jannatan_loop_category_label() {
	global $product;
	if ( ! $product instanceof WC_Product ) {
		return;
	}
	$terms = get_the_terms( $product->get_id(), 'product_cat' );
	if ( ! $terms || is_wp_error( $terms ) ) {
		return;
	}
	echo '<p class="category">' . esc_html( $terms[0]->name ) . '</p>';
}
add_action( 'woocommerce_shop_loop_item_title', 'jannatan_loop_category_label', 4 );

/* -------------------------------------------------------------------------
 * 11) نصوص أوضح داخل المتجر
 * ---------------------------------------------------------------------- */
function jannatan_gettext( $translated, $text, $domain ) {
	if ( 'woocommerce' !== $domain ) {
		return $translated;
	}
	$map = array(
		'Related products'    => __( 'You may also like', 'jannatan' ),
		'Proceed to checkout' => __( 'Secure checkout', 'jannatan' ),
		'Update cart'         => __( 'Update', 'jannatan' ),
	);
	return isset( $map[ $text ] ) ? $map[ $text ] : $translated;
}
add_filter( 'gettext', 'jannatan_gettext', 20, 3 );

/* -------------------------------------------------------------------------
 * 12) أداء: إيقاف سكربتات لا تُستخدم إلا في صفحات بعينها
 * ---------------------------------------------------------------------- */
function jannatan_dequeue_unused() {

	// أنماط WooCommerce الخاصة بالمعرض لا تلزم خارج صفحة المنتج.
	if ( function_exists( 'is_product' ) && ! is_product() ) {
		wp_dequeue_style( 'woocommerce_prettyPhoto_css' );
	}

	// Contact Form 7 يُحمَّل في كل صفحة افتراضياً.
	if ( ! is_page( array( 'contact', 'contact-us' ) ) ) {
		wp_dequeue_style( 'contact-form-7' );
		wp_dequeue_script( 'contact-form-7' );
	}
}
add_action( 'wp_enqueue_scripts', 'jannatan_dequeue_unused', 99 );

/* -------------------------------------------------------------------------
 * 13) دعم RTL تلقائي عند تفعيل اللغة العربية
 * ---------------------------------------------------------------------- */
function jannatan_rtl_attr( $output ) {
	if ( is_rtl() && false === strpos( $output, 'dir=' ) ) {
		$output .= ' dir="rtl"';
	}
	return $output;
}
add_filter( 'language_attributes', 'jannatan_rtl_attr' );
