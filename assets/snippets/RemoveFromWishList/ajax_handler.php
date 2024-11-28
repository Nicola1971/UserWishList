<?php
define('MODX_API_MODE', true);
include_once("../../../index.php");
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
                'message' => 'Rimosso dalla WishList'
            ]);
        } else {
            echo json_encode([
                'success' => false,
                'docid' => $docid,
                'message' => 'Elemento non presente nella WishList'
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