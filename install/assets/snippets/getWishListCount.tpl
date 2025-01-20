/**
 * getWishListCount
 *
 * Counter snippet for UserWishList
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
$tpl = isset($tpl) ? $tpl : '@CODE:[+count+]';
$noneTPL = isset($noneTPL) ? $noneTPL : '@CODE:[+count+]';

// 3. FUNZIONE HELPER PER TEMPLATE
if (!function_exists('parseWishListTemplate')) {
    function parseWishListTemplate($modx, $tpl, $placeholders) {
        if (substr($tpl, 0, 6) == "@CODE:") {
            $content = substr($tpl, 6);
            foreach ($placeholders as $key => $value) {
                $content = str_replace("[+" . $key . "+]", $value, $content);
            }
            return $content;
        }
        return $modx->parseChunk($tpl, $placeholders);
    }
}

// 4. OUTPUT
if ($docid > 0) {
    $count = getUserWishlistProductCount($docid, $userTv);
    $template = ($count > 0) ? $tpl : $noneTPL;
    return parseWishListTemplate($modx, $template, ['count' => $count]);
}
return '';
