<?php
define('MODX_API_MODE', true);
include_once("../../../../../index.php");
require_once "../functions.php";

//Language
$_UWLlang = array();
$langPath = dirname(dirname(dirname(__FILE__))) . '/lang/';
include($langPath . 'en.php');
if (file_exists($langPath . $modx->config['manager_language'] . '.php')) {
    include($langPath . $modx->config['manager_language'] . '.php');
}

$evo = evolutionCMS();
$evo->db->connect();
header('Content-Type: application/json');

if (isset($_POST['get_wishlist_count'])) {
    $docid = (int)$_POST['docid'];
    $count = getUserWishlistProductCount($docid, 'UserWishList');
    
    die(json_encode([
        'success' => true,
        'count' => $count,
        'docid' => $docid,
        'formatted_count' => sprintf($_UWLlang['counter_format'], $count)
    ]));
}

if (isset($_POST['add_to_wishlist'])) {
    try {
        $docid = (int)$_POST['docid'];
        $userId = $_POST['userId'];
        $userTv = 'UserWishList';
        
        $tvValues = \UserManager::getValues(['id' => $userId]);
        
        $userWishList = isset($tvValues[$userTv]) ? $tvValues[$userTv] : '';
        $wishListIds = array_filter(array_map('trim', explode(',', $userWishList)));
        
        if (!in_array($docid, $wishListIds)) {
            $wishListIds[] = $docid;
            $userWishList = implode(',', $wishListIds);
            
            $userData = ['id' => $userId, $userTv => $userWishList];
            \UserManager::saveValues($userData);
            
            $count = getUserWishlistProductCount($docid, $userTv);
            
            die(json_encode([
                'success' => true,
                'docid' => $docid,
                'message' => $_UWLlang['added_to_wishList'],
                'count' => $count,
                'formatted_count' => sprintf($_UWLlang['counter_format'], $count)
            ]));
        }
        
        $count = getUserWishlistProductCount($docid, $userTv);
        
        die(json_encode([
            'success' => false,
            'docid' => $docid,
            'message' => $_UWLlang['already_in_wishList'],
            'count' => $count,
            'formatted_count' => sprintf($_UWLlang['counter_format'], $count)
        ]));
    } catch (\Exception $e) {
        $count = getUserWishlistProductCount($docid, $userTv);
        
        die(json_encode([
            'success' => false,
            'docid' => $docid,
            'error' => $e->getMessage(),
            'count' => $count,
            'formatted_count' => sprintf($_UWLlang['counter_format'], $count)
        ]));
    }
}
exit();