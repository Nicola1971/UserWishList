<?php
define('MODX_API_MODE', true);
include_once("../../../../../index.php");
//Language
$_UWLlang = array();
include('../../lang/en.php');
if (file_exists('../../lang/' . $modx->config['manager_language'] . '.php')) {
    include('../../lang/' . $modx->config['manager_language'] . '.php');
}
$evo = evolutionCMS();
$evo->db->connect();

header('Content-Type: application/json');

if (isset($_POST['remove_from_wishlist'])) {
    try {
        $docid = (int)$_POST['docid'];
        $userId = $_POST['userId'];
        $userTv = 'UserWishList';
        
        $tvValues = \UserManager::getValues(['id' => $userId]);
        
        $userWishList = isset($tvValues[$userTv]) ? $tvValues[$userTv] : '';
        $wishListIds = $userWishList ? explode(',', $userWishList) : [];
        
        if (in_array($docid, $wishListIds)) {
            // Rimuovi l'ID dalla lista
            $wishListIds = array_diff($wishListIds, [$docid]);
            $userWishList = implode(',', $wishListIds);
            
            $userData = ['id' => $userId, $userTv => $userWishList];
            \UserManager::saveValues($userData);
            
            echo json_encode([
                'success' => true,
                'docid' => $docid,
                'message' => $_UWLlang['removed_from_wishList']
            ]);
        } else {
            echo json_encode([
                'success' => false,
                'docid' => $docid,
                'message' => $_UWLlang['item_notin_wishList']
            ]);
        }
    } catch (\Exception $e) {
        echo json_encode([
            'success' => false,
            'docid' => $docid,
            'error' => $e->getMessage()
        ]);
    }
}
exit();
?>