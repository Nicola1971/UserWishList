/**
 * AddToWishListCounter
 *
 * Counter for WishList
 *
 * @author    Nicola Lambathakis http://www.tattoocms.it/
 * @category  snippet
 * @version   1.0
 * @internal  @modx_category UserWishList
 */

// 1. INCLUSIONE DIPENDENZE
require_once MODX_BASE_PATH . 'assets/snippets/UserWishList/includes/functions.php';

// 2. SETUP VARIABILI
$docid = isset($docid) ? (int)$docid : 0;
$userTv = isset($userTv) ? (string)$userTv : 'UserWishList';
$tpl = isset($tpl) ? $tpl : '[+count+]';
$noneTpl = isset($noneTpl) ? $noneTpl : '[+count+]';

// 3. OUTPUT
if ($docid > 0) {
    $count = getUserWishlistProductCount($docid, $userTv);
    $template = ($count > 0) ? $tpl : $noneTpl;
    $output = str_replace('[+count+]', $count, $template);
    return $output;
}
return '';