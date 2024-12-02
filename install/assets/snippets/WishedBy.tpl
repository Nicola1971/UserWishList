/**
 * WishedBy
 * 
 * Shows users who have added a product to their wishlist
 * 
 * @author    Nicola Lambathakis http://www.tattoocms.it/
 * @category  snippet
 * @version   1.0
 * @internal  @modx_category UserWishList
 * @lastupdate 02-12-2024 17:54
 */

// Get parameters
$docid = isset($docid) ? $docid : $modx->documentIdentifier;
$display = isset($display) ? (int)$display : 10;
$tpl = isset($tpl) ? $tpl : '';
$outerTpl = isset($outerTpl) ? $outerTpl : '';
$userTv = isset($userTv) ? (string)$userTv : 'UserWishList';
$orderBy = isset($orderBy) ? (string)$orderBy : 'username';
$orderDir = isset($orderDir) ? strtoupper($orderDir) : 'ASC';

// Validate parameters
if (empty($docid)) return '';
if (empty($tpl)) return 'Parameter &tpl is required';
if (empty($outerTpl)) return 'Parameter &outerTpl is required';

// Validate and sanitize order parameters
$allowedFields = ['id', 'username', 'fullname', 'first_name', 'last_name', 'email'];
if (!in_array($orderBy, $allowedFields)) $orderBy = 'username';
if (!in_array($orderDir, ['ASC', 'DESC'])) $orderDir = 'ASC';

// Prepare ORDER BY clause
$orderByClause = '';
switch($orderBy) {
    case 'id':
        $orderByClause = "ua.internalKey {$orderDir}";
        break;
    case 'username':
        $orderByClause = "u.username {$orderDir}";
        break;
    case 'fullname':
    case 'first_name':
    case 'last_name':
    case 'email':
        $orderByClause = "ua.{$orderBy} {$orderDir}";
        break;
}

// Get all users
$output = array();
$total = 0;

$query = "SELECT ua.internalKey, u.username, ua.email, ua.fullname, ua.first_name, ua.last_name 
          FROM " . $modx->getFullTableName('user_attributes') . " ua
          JOIN " . $modx->getFullTableName('users') . " u ON u.id = ua.internalKey
          ORDER BY {$orderByClause}";

$allUsers = $modx->db->query($query);
while ($user = $modx->db->getRow($allUsers)) {
    $userId = $user['internalKey'];
    
    try {
        $userData = \UserManager::getValues(['id' => $userId]);
        $wishlist = !empty($userData[$userTv]) ? $userData[$userTv] : '';
        
        if (!empty($wishlist) && in_array($docid, explode(',', $wishlist))) {
            $placeholders = array(
                'userid' => $userId,
                'username' => !empty($user['username']) ? $user['username'] : "User-".$userId,
                'fullname' => !empty($user['fullname']) ? $user['fullname'] : (!empty($user['username']) ? $user['username'] : "User-".$userId),
                'email' => $user['email'],
                'first_name' => $user['first_name'],
                'last_name' => $user['last_name']
            );
            
            $output[] = parseTemplate($modx, $tpl, $placeholders);
            $total++;
            
            if ($total >= $display) break;
        }
    } catch (\EvolutionCMS\Exceptions\ServiceValidationException $exception) {
        // Silently skip users with validation errors
        continue;
    } catch (\EvolutionCMS\Exceptions\ServiceActionException $exception) {
        // Silently skip users with action errors
        continue;
    }
}

// Process template type (chunk or inline)
function parseTemplate($modx, $tpl, $placeholders) {
    if (substr($tpl, 0, 6) == "@CODE:") {
        $content = substr($tpl, 6);
        foreach ($placeholders as $key => $value) {
            $content = str_replace('[+'.$key.'+]', $value, $content);
        }
        return $content;
    } else {
        return $modx->parseChunk($tpl, $placeholders);
    }
}

// If no results
if (empty($output)) return '';

// Process outer template
$outerPlaceholders = array(
    'total' => $total,
    'items' => implode("\n", $output)
);

return parseTemplate($modx, $outerTpl, $outerPlaceholders);