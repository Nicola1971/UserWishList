<?php
define('MODX_API_MODE', true);
include_once("../../../../index.php");
require_once "functions.php";

$evo = evolutionCMS();
$evo->db->connect();

header('Content-Type: application/json');

if (isset($_POST['get_wishlist_count'])) {
    $docid = (int)$_POST['docid'];
    $count = getUserWishlistProductCount($docid, 'UserWishList');
    
    die(json_encode([
        'success' => true,
        'count' => $count,
        'docid' => $docid
    ]));
}

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
            
            die(json_encode([
                'success' => true,
                'docid' => $docid,
                'message' => 'Aggiunto alla WishList',
                'count' => getUserWishlistProductCount($docid, $userTv)
            ]));
        }
        
        die(json_encode([
            'success' => false,
            'docid' => $docid,
            'message' => 'Già presente nella WishList',
            'count' => getUserWishlistProductCount($docid, $userTv)
        ]));
    } catch (\Exception $e) {
        die(json_encode([
            'success' => false,
            'docid' => $docid,
            'error' => $e->getMessage(),
            'count' => getUserWishlistProductCount($docid, $userTv)
        ]));
    }
}
exit();
?>