<?php
define('MODX_API_MODE', true);
include_once("../../../index.php");
$evo = evolutionCMS();
$evo->db->connect();

header('Content-Type: application/json');

if (isset($_POST['add_to_wishlist'])) {
    try {
        $docid = (int)$_POST['docid'];
        $userId = $_POST['userId'];
        $userTv = 'UserWishList';
        
        $tvValues = \UserManager::getValues(['id' => $userId]);
        
        $userWishList = isset($tvValues[$userTv]) ? $tvValues[$userTv] : '';
        $wishListIds = $userWishList ? explode(',', $userWishList) : [];
        
        if (!in_array($docid, $wishListIds)) {
            $wishListIds[] = $docid;
            $userWishList = implode(',', $wishListIds);
            
            $userData = ['id' => $userId, $userTv => $userWishList];
            \UserManager::saveValues($userData);
            
            echo json_encode([
                'success' => true,
                'docid' => $docid,
                'message' => 'Aggiunto alla WishList'
            ]);
        } else {
            echo json_encode([
                'success' => false,
                'docid' => $docid,
                'message' => 'Già presente nella WishList'
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