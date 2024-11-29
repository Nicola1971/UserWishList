<?php
if (!function_exists('getUserWishlistProductCount')) {
    function getUserWishlistProductCount($docid, $userTv) {
        $evo = evolutionCMS();
        try {
            // Prima otteniamo l'ID della TV
            $tvQuery = $evo->db->select(
                "id",
                "[+prefix+]site_tmplvars",
                "name = '{$userTv}'"
            );
            
            if ($tvRow = $evo->db->getRow($tvQuery)) {
                $tvId = $tvRow['id'];
                
                // Ora possiamo contare gli utenti
                $query = $evo->db->select(
                    "COUNT(DISTINCT userid) as total",
                    "[+prefix+]user_values",
                    "tmplvarid = {$tvId} AND FIND_IN_SET('{$docid}', value)"
                );
                
                if ($row = $evo->db->getRow($query)) {
                    return (int)$row['total'];
                }
            }
        } catch (\Exception $e) {
            return 0;
        }
        return 0;
    }
}
?>