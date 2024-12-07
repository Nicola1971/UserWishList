<?php
if (!function_exists('getUserWishlistProductCount')) {
    /**
     * Ottiene il numero di utenti che hanno un determinato prodotto nella loro wishlist
     * 
     * @param int $docId ID del documento/prodotto
     * @param string $userTv Nome della TV che contiene la wishlist
     * @return int Numero di utenti
     */
    function getUserWishlistProductCount($docId, $userTv = 'UserWishList') {
    $evo = evolutionCMS();
    
    // Sanitize input
    $docId = (int)$docId;
    $userTv = preg_replace('/[^a-zA-Z0-9_-]/', '', $userTv);
    
    // Get TV ID
    $tvQuery = $evo->db->select(
        'id',
        $evo->getFullTableName('site_tmplvars'),
        "name = '" . $evo->db->escape($userTv) . "'"
    );
    
    if ($evo->db->getRecordCount($tvQuery) === 0) {
        return 0;
    }
    
    $tvId = $evo->db->getValue($tvQuery);
    
    // Count users who have this doc in their wishlist
    $query = $evo->db->select(
        'COUNT(DISTINCT userid) as count',  // Cambiato da user_id a userid
        $evo->getFullTableName('user_values'),
        "tmplvarid = {$tvId} AND FIND_IN_SET({$docId}, value)"
    );
    
    return (int)$evo->db->getValue($query);
}
}

if (!function_exists('getWishlistDocuments')) {
    /**
     * Ottiene la lista dei documenti nella wishlist di un utente
     * 
     * @param int $userId ID dell'utente
     * @param string $userTv Nome della TV che contiene la wishlist
     * @return array Array di ID dei documenti
     */
    function getWishlistDocuments($userId, $userTv = 'UserWishList') {
        // Sanitize input
        $userId = (int)$userId;
        $userTv = preg_replace('/[^a-zA-Z0-9_-]/', '', $userTv);
        
        try {
            $tvValues = \UserManager::getValues(['id' => $userId]);
            $userWishList = isset($tvValues[$userTv]) ? $tvValues[$userTv] : '';
            
            if (empty($userWishList)) {
                return [];
            }
            
            // Split the comma-separated list and ensure they're all integers
            $wishListIds = array_map('intval', array_filter(array_map('trim', explode(',', $userWishList))));
            
            return array_values(array_unique($wishListIds));
        } catch (\Exception $e) {
            return [];
        }
    }
}

if (!function_exists('isDocumentInWishlist')) {
    /**
     * Verifica se un documento è nella wishlist di un utente
     * 
     * @param int $docId ID del documento
     * @param int $userId ID dell'utente
     * @param string $userTv Nome della TV che contiene la wishlist
     * @return bool
     */
    function isDocumentInWishlist($docId, $userId, $userTv = 'UserWishList') {
        $wishlistDocs = getWishlistDocuments($userId, $userTv);
        return in_array((int)$docId, $wishlistDocs);
    }
}

if (!function_exists('addToWishlist')) {
    /**
     * Aggiunge un documento alla wishlist di un utente
     * 
     * @param int $docId ID del documento
     * @param int $userId ID dell'utente
     * @param string $userTv Nome della TV che contiene la wishlist
     * @return bool
     */
    function addToWishlist($docId, $userId, $userTv = 'UserWishList') {
        try {
            $docId = (int)$docId;
            $userId = (int)$userId;
            $userTv = preg_replace('/[^a-zA-Z0-9_-]/', '', $userTv);
            
            if (isDocumentInWishlist($docId, $userId, $userTv)) {
                return false;
            }
            
            $tvValues = \UserManager::getValues(['id' => $userId]);
            $userWishList = isset($tvValues[$userTv]) ? $tvValues[$userTv] : '';
            $wishListIds = $userWishList ? array_filter(array_map('trim', explode(',', $userWishList))) : [];
            
            $wishListIds[] = $docId;
            $userWishList = implode(',', array_unique($wishListIds));
            
            $userData = ['id' => $userId, $userTv => $userWishList];
            \UserManager::saveValues($userData);
            
            return true;
        } catch (\Exception $e) {
            return false;
        }
    }
}

if (!function_exists('removeFromWishlist')) {
    /**
     * Rimuove un documento dalla wishlist di un utente
     * 
     * @param int $docId ID del documento
     * @param int $userId ID dell'utente
     * @param string $userTv Nome della TV che contiene la wishlist
     * @return bool
     */
    function removeFromWishlist($docId, $userId, $userTv = 'UserWishList') {
        try {
            $docId = (int)$docId;
            $userId = (int)$userId;
            $userTv = preg_replace('/[^a-zA-Z0-9_-]/', '', $userTv);
            
            if (!isDocumentInWishlist($docId, $userId, $userTv)) {
                return false;
            }
            
            $tvValues = \UserManager::getValues(['id' => $userId]);
            $userWishList = isset($tvValues[$userTv]) ? $tvValues[$userTv] : '';
            $wishListIds = $userWishList ? array_filter(array_map('trim', explode(',', $userWishList))) : [];
            
            $wishListIds = array_diff($wishListIds, [$docId]);
            $userWishList = implode(',', array_unique($wishListIds));
            
            $userData = ['id' => $userId, $userTv => $userWishList];
            \UserManager::saveValues($userData);
            
            return true;
        } catch (\Exception $e) {
            return false;
        }
    }
}