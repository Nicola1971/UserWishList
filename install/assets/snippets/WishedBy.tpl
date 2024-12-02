/**
 * WishedBy
 *
 * Shows users who have added a product to their wishlist
 *
 * @author    Nicola Lambathakis http://www.tattoocms.it/
 * @category  snippet
 * @version   1.1
 * @internal  @modx_category UserWishList
 * @lastupdate 02-12-2024 19:30
 */

// Parameters
$docid = isset($docid) ? $docid : $modx->documentIdentifier;
$display = isset($display) ? (int) $display : 10;
$tpl = isset($tpl) ? $tpl : "";
$outerTpl = isset($outerTpl) ? $outerTpl : "";
$userTv = isset($userTv) ? (string) $userTv : "UserWishList";
$privateWishTv = isset($privateWishTv)
    ? (string) $privateWishTv
    : "PrivateWishList";
$orderBy = isset($orderBy) ? (string) $orderBy : "username";
$orderDir = isset($orderDir) ? strtoupper($orderDir) : "ASC";

if (empty($docid) || empty($tpl) || empty($outerTpl)) {
    return "";
}

// Validate order
$allowedFields = [
    "id",
    "username",
    "fullname",
    "first_name",
    "last_name",
    "email",
    "random"
];
if (!in_array($orderBy, $allowedFields)) {
    $orderBy = "username";
}
if (!in_array($orderDir, ["ASC", "DESC"])) {
    $orderDir = "ASC";
}

$orderByClause = match ($orderBy) {
    "id" => "ua.internalKey {$orderDir}",
    "username" => "u.username {$orderDir}",
    "random" => "RAND()",
    default => "ua.{$orderBy} {$orderDir}"
};

// Get users
$output = [];
$totalWishers = 0;
$visibleUsers = 0;

$query =
    "SELECT ua.internalKey, u.username, ua.email, ua.fullname, ua.first_name, ua.last_name 
          FROM " .
    $modx->getFullTableName("user_attributes") .
    " ua
          JOIN " .
    $modx->getFullTableName("users") .
    " u ON u.id = ua.internalKey
          ORDER BY {$orderByClause}";
// Count total wishlist users (including private ones)
$totalVisible = 0;
$countQuery = "SELECT ua.internalKey FROM " . $modx->getFullTableName("user_attributes") . " ua
          JOIN " . $modx->getFullTableName("users") . " u ON u.id = ua.internalKey";
          
$allUsers = $modx->db->query($countQuery);
while ($user = $modx->db->getRow($allUsers)) {
    try {
        $userData = \UserManager::getValues(["id" => $user["internalKey"]]);
        $wishlist = !empty($userData[$userTv]) ? $userData[$userTv] : "";
        
        if (!empty($wishlist) && in_array($docid, explode(",", $wishlist))) {
            $totalVisible++;
        }
    } catch (\EvolutionCMS\Exceptions\ServiceValidationException | \EvolutionCMS\Exceptions\ServiceActionException $e) {
        continue;
    }
}

// Get users with details
$shownUsers = 0;
$mainQuery = "SELECT ua.internalKey, u.username, ua.email, ua.fullname, ua.first_name, ua.last_name 
          FROM " . $modx->getFullTableName("user_attributes") . " ua
          JOIN " . $modx->getFullTableName("users") . " u ON u.id = ua.internalKey
          ORDER BY {$orderByClause}";

$allUsers = $modx->db->query($mainQuery);
while ($user = $modx->db->getRow($allUsers)) {
    try {
        $userData = \UserManager::getValues(["id" => $user["internalKey"]]);
        $wishlist = !empty($userData[$userTv]) ? $userData[$userTv] : "";
        
        if (!empty($wishlist) && in_array($docid, explode(",", $wishlist))) {
            if (!empty($userData[$privateWishTv]) && $userData[$privateWishTv] == "1") {
                continue;
            }
            
            if ($shownUsers < $display) {
                $placeholders = [
                    "userid" => $user["internalKey"],
                    "username" => $user["username"],
                    "fullname" => $user["fullname"] ?: $user["username"],
                    "email" => $user["email"],
                    "first_name" => $user["first_name"],
                    "last_name" => $user["last_name"],
                ];
                
                $output[] = parseTemplate($modx, $tpl, $placeholders);
                $shownUsers++;
            }
        }
    } catch (\EvolutionCMS\Exceptions\ServiceValidationException | \EvolutionCMS\Exceptions\ServiceActionException $e) {
        continue;
    }
}

function parseTemplate($modx, $tpl, $placeholders)
{
    if (substr($tpl, 0, 6) == "@CODE:") {
        $content = substr($tpl, 6);
        foreach ($placeholders as $key => $value) {
            $content = str_replace("[+" . $key . "+]", $value, $content);
        }
        return $content;
    }
    return $modx->parseChunk($tpl, $placeholders);
}

if (empty($output)) {
    return "";
}

return parseTemplate($modx, $outerTpl, [
    "total" => $totalVisible,
    "visible" => $shownUsers,
    "hidden" => $totalVisible - $shownUsers,
    "items" => implode("\n", $output),
]);