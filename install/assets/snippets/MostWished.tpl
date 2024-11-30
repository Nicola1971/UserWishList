/**
 * MostWished
 * 
 * Mostra i prodotti più desiderati dagli utenti
 * 
 * @author    Nicola Lambathakis http://www.tattoocms.it/
 * @category  snippet
 * @version   1.5
 * @internal  @modx_category UserWishList
 */

$userTv = isset($userTv) ? (string)$userTv : 'UserWishList';
$limit = isset($limit) ? (int)$limit : 10;
$tpl = isset($tpl) ? $tpl : '@CODE:
    <div class="most-wished-item">
        <h3>[+pagetitle+]</h3>
        <p>[+introtext+]</p>
        <span class="badge bg-info">Salvato da [+wishlist_count+] utenti</span>
        [!AddToWishList? &docid=`[+id+]`!]
    </div>';

try {
    // Prima otteniamo l'ID della TV
    $tvQuery = $modx->db->select(
        "id",
        "[+prefix+]site_tmplvars",
        "name = '{$userTv}'"
    );
    
    if ($tvRow = $modx->db->getRow($tvQuery)) {
        $tvId = $tvRow['id'];
        
        // Query per ottenere il conteggio di ogni ID
        $query = $modx->db->query("
            SELECT 
                SUBSTRING_INDEX(SUBSTRING_INDEX(value, ',', n.n), ',', -1) AS docid,
                COUNT(DISTINCT userid) as count
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
            GROUP BY docid
            ORDER BY count DESC
            LIMIT {$limit}
        ");
        
        $docCounts = [];
        while ($row = $modx->db->getRow($query)) {
            $docCounts[$row['docid']] = (int)$row['count'];
        }
        
        if (empty($docCounts)) {
            return '<p>Nessun prodotto nella wishlist</p>';
        }
        
        // Prepara i parametri per DocLister
        $params = array(
            'api' => '1',
            'documents' => implode(',', array_keys($docCounts)),
            'debug' => isset($debug) ? $debug : '0',
            'tvPrefix' => isset($tvPrefix) ? $tvPrefix : '',
            'tvList' => isset($tvList) ? $tvList : '',
            'selectFields' => isset($selectFields) ? $selectFields : 'id,pagetitle,introtext',
            'orderBy' => 'FIELD(c.id, ' . implode(',', array_keys($docCounts)) . ')'
        );
        
        $output = '';
        $items = json_decode($modx->runSnippet('DocLister', $params), true);
        
        if(isset($debug) && $debug == '1') {
            echo "<pre>DocLister params: ";
            print_r($params);
            echo "\nDocLister results: ";
            print_r($items);
            echo "</pre>";
        }
        
        if (is_array($items)) {
            foreach ($items as $item) {
                $count = $docCounts[$item['id']] ?? 0;
                
                if (substr($tpl, 0, 6) === '@CODE:') {
                    $itemTemplate = substr($tpl, 6);
                } else {
                    $itemTemplate = $modx->getChunk($tpl);
                }
                
                // Prepara array di sostituzione
                $replacements = array(
                    '[+id+]' => $item['id'],
                    '[+pagetitle+]' => $item['pagetitle'],
                    '[+introtext+]' => $item['introtext'],
                    '[+wishlist_count+]' => $count
                );
                
                // Aggiungi TV se presenti
                if (isset($tvList) && !empty($tvList)) {
                    $tvs = explode(',', $tvList);
                    $prefix = isset($tvPrefix) ? $tvPrefix : '';
                    foreach ($tvs as $tv) {
                        $tvKey = $prefix . trim($tv);
                        $replacements['[+' . $tvKey . '+]'] = $item[$tvKey] ?? '';
                    }
                }
                
                $itemHtml = str_replace(
                    array_keys($replacements),
                    array_values($replacements),
                    $itemTemplate
                );
                
                $output .= $itemHtml;
            }
        }
        
        return '<div class="row most-wished-container">' . $output . '</div>';
    }
    
} catch (\Exception $e) {
    return 'Errore: ' . $e->getMessage();
}

return '<p>Template Variable non trovata</p>';