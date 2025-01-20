<?php
define('MODX_API_MODE', true);
include_once("../../../../../index.php");
require_once "../functions.php";

//Language
// Sanitizzazione input e cast a string
$customLang = isset($_POST['customLang']) ? (string)$_POST['customLang'] : '';  // Prendiamo il customLang dalla POST
$customLang = preg_replace('/[^a-zA-Z0-9_-]/', '', $customLang);
$customLang = basename($customLang);

// Inizializzazione array lingue
$_UWLlang = [];

// Percorso base per i file di lingua
$langBasePath = MODX_BASE_PATH . 'assets/snippets/UserWishList/lang/';

// Caricamento file lingua personalizzato
if ($customLang !== '' && file_exists($langBasePath . 'custom/' . $customLang . '.php')) {
    include ($langBasePath . 'custom/' . $customLang . '.php');
} else {
    // Carica sempre l'inglese come fallback
    include ($langBasePath . 'en.php');
    
    // Carica la lingua del manager se disponibile e diversa dall'inglese
    $managerLang = $modx->config['manager_language'];
    $managerLang = preg_replace('/[^a-zA-Z0-9_-]/', '', $managerLang);
    $managerLang = basename($managerLang);
    
    if ($managerLang !== 'en' && file_exists($langBasePath . $managerLang . '.php')) {
        include ($langBasePath . $managerLang . '.php');
    }
}
$added_msg = isset($_POST['added_msg']) && !empty($_POST['added_msg']) ? (string)$_POST['added_msg'] : $_UWLlang['added_to_wishList'];
$evo = evolutionCMS();
$evo->db->connect();
header('Content-Type: application/json');

// Sanitize userTv input
$userTv = isset($_POST['userTv']) ? preg_replace('/[^a-zA-Z0-9_-]/', '', $_POST['userTv']) : 'UserWishList';

if (isset($_POST['get_wishlist_count'])) {
    $docid = (int)$_POST['docid'];
    $count = getUserWishlistProductCount($docid, $userTv);
    
    echo json_encode([
        'success' => true,
        'count' => $count,
        'docid' => $docid,
        'formatted_count' => sprintf($_UWLlang['counter_format'], $count),
        'alreadyText' => $_UWLlang['btnAlreadyText']
    ]);
    exit();
}

if (isset($_POST['add_to_wishlist'])) {
    try {
        $docid = (int)$_POST['docid'];
        $userId = (int)$_POST['userId'];
        
        // Verify TV exists
        $tvQuery = $evo->db->select('id', $evo->getFullTableName('site_tmplvars'), "name = '" . $evo->db->escape($userTv) . "'");
        if ($evo->db->getRecordCount($tvQuery) === 0) {
            echo json_encode([
                'success' => false,
                'message' => 'Invalid TV name',
                'docid' => $docid,
                'alreadyText' => $_UWLlang['btnAlreadyText']
            ]);
            exit();
        }
        
        $tvValues = \UserManager::getValues(['id' => $userId]);
        
        $userWishList = isset($tvValues[$userTv]) ? $tvValues[$userTv] : '';
        $wishListIds = array_filter(array_map('trim', explode(',', $userWishList)));
        
        if (!in_array($docid, $wishListIds)) {
            $wishListIds[] = $docid;
            $userWishList = implode(',', array_unique($wishListIds));
            
            $userData = ['id' => $userId, $userTv => $userWishList];
            \UserManager::saveValues($userData);
            
            $count = getUserWishlistProductCount($docid, $userTv);
            
            echo json_encode([
                'success' => true,
                'docid' => $docid,
                'message' => $added_msg,
                'count' => $count,
                'formatted_count' => sprintf($_UWLlang['counter_format'], $count)
            ]);
            exit();
        }
        
        $count = getUserWishlistProductCount($docid, $userTv);
        
        echo json_encode([
            'success' => false,
            'docid' => $docid,
            'message' => $_UWLlang['already_in_wishList'],
            'count' => $count,
            'formatted_count' => sprintf($_UWLlang['counter_format'], $count)
        ]);
        exit();
        
    } catch (\Exception $e) {
        echo json_encode([
            'success' => false,
            'docid' => $docid,
            'message' => $e->getMessage(),
            'count' => 0,
            'formatted_count' => sprintf($_UWLlang['counter_format'], 0)
        ]);
        exit();
    }
}

// Se arriviamo qui, nessuna azione valida è stata specificata
echo json_encode([
    'success' => false,
    'message' => 'Invalid action',
    'alreadyText' => $_UWLlang['btnAlreadyText']
]);
exit();