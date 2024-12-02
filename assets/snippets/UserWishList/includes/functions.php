<?php
if (!function_exists('getUserWishlistProductCount')) {
    function getUserWishlistProductCount($docid, $userTv) {
        $evo = evolutionCMS();
        try {
            $docid = (int)$docid;
            $userTv = $evo->db->escape($userTv);
            
            $tvQuery = $evo->db->select(
                "id",
                "[+prefix+]site_tmplvars",
                "name = '{$userTv}'"
            );
            
            if ($tvRow = $evo->db->getRow($tvQuery)) {
                $tvId = $tvRow['id'];
                
                $query = $evo->db->query("
                    SELECT 
                        COUNT(DISTINCT userid) as total
                    FROM 
                        [+prefix+]user_values uv
                        CROSS JOIN (
                            SELECT a.N + b.N * 10 + 1 n
                            FROM 
                                (SELECT 0 AS N UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) a,
                                (SELECT 0 AS N UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) b
                            ORDER BY n
                        ) n
                    WHERE 
                        tmplvarid = {$tvId}
                        AND n.n <= 1 + (LENGTH(value) - LENGTH(REPLACE(value, ',', '')))
                        AND TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(value, ',', n.n), ',', -1)) = '{$docid}'
                ");
                
                if ($row = $evo->db->getRow($query)) {
                    return (int)$row['total'];
                }
            }
            return 0;
        } catch (\Exception $e) {
            error_log("Error in getUserWishlistProductCount: " . $e->getMessage());
            return 0;
        }
    }
}