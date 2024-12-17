/**
 * MostWished
 *
 * Show the products most desired by users
 *
 * @author    Nicola Lambathakis http://www.tattoocms.it/
 * @category  snippet
 * @version   1.6.4
 * @internal  @modx_category UserWishList
 * @lastupdate 17-12-2024 19:30
 */

//Language
// Sanitizzazione input e cast a string
$customLang = isset($customLang) ? (string)$customLang : '';
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

// Parametri snippet
$userTv = isset($userTv) ? (string)$userTv : 'UserWishList';
$limit = isset($limit) ? (int)$limit : 10;

// Template predefinito con nuovo placeholder [+iteration+]
$tpl = isset($tpl) ? $tpl : '@CODE:
    <div class="most-wished-item">
        <span class="position">#[+iteration+]</span>
        <h3>[+pagetitle+]</h3>
        <p>[+summary+]</p>
        <span class="badge bg-info">Salvato da [+wishlist_count+] utenti</span>
        [!AddToWishList? &docid=`[+id+]`!]
    </div>';

try {
    // Get TV ID with explicit table name
    $tvQuery = $modx->db->select(
        "id", 
        $modx->getFullTableName('site_tmplvars'), 
        "name = '" . $modx->db->escape($userTv) . "'"
    );
    
    if ($tvRow = $modx->db->getRow($tvQuery)) {
        $tvId = $tvRow['id'];
        
        // Query per ottenere il conteggio di ogni ID con gestione valori separati da virgola
        $query = $modx->db->query("
            WITH RECURSIVE split_values AS (
                SELECT 
                    userid,
                    SUBSTRING_INDEX(SUBSTRING_INDEX(value, ',', n.n), ',', -1) AS docid
                FROM 
                    " . $modx->getFullTableName('user_values') . " uv
                    CROSS JOIN (
                        SELECT a.N + b.N * 10 + 1 n
                        FROM 
                            (SELECT 0 AS N UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) a,
                            (SELECT 0 AS N UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) b
                        ORDER BY n
                    ) n
                WHERE 
                    tmplvarid = {$tvId}
                    AND value != ''
                    AND n.n <= 1 + (LENGTH(value) - LENGTH(REPLACE(value, ',', '')))
            )
            SELECT 
                docid,
                COUNT(DISTINCT userid) as count
            FROM 
                split_values
            WHERE 
                docid REGEXP '^[0-9]+$'
            GROUP BY 
                docid
            ORDER BY 
                count DESC, docid ASC
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
            'summary' => isset($summary) ? $summary : 'notags,len:300',
            'orderBy' => 'FIELD(c.id, ' . implode(',', array_keys($docCounts)) . ')'
        );

        $output = '';
        $items = json_decode($modx->runSnippet('DocLister', $params), true);

        if (isset($debug) && $debug == '1') {
            echo "<pre>DocLister params: ";
            print_r($params);
            echo "\nDocLister results: ";
            print_r($items);
            echo "</pre>";
        }

        if (is_array($items)) {
            $iteration = 0; // Inizializzazione contatore
            foreach ($items as $item) {
                $iteration++; // Incremento contatore
                $count = $docCounts[$item['id']]??0;
                
                // Gestione template
                if (substr($tpl, 0, 6) === '@CODE:') {
                    $itemTemplate = substr($tpl, 6);
                } else {
                    $itemTemplate = $modx->getChunk($tpl);
                }
                
                // Preparazione placeholder con aggiunta di [+iteration+]
                $replacements = array(
                    '[+id+]' => $item['id'],
                    '[+pagetitle+]' => $item['pagetitle'],
                    '[+title+]' => $item['title'],
                    '[+introtext+]' => $item['introtext'],
                    '[+wishlist_count+]' => $count,
                    '[+summary+]' => $item['summary'],
                    '[+iteration+]' => $iteration // Nuovo placeholder per l'iterazione
                );

                // Gestione TV aggiuntive
                if (isset($tvList) && !empty($tvList)) {
                    $tvs = explode(',', $tvList);
                    $prefix = isset($tvPrefix) ? $tvPrefix : '';
                    foreach ($tvs as $tv) {
                        $tvKey = $prefix . trim($tv);
                        $replacements['[+' . $tvKey . '+]'] = $item[$tvKey]??'';
                    }
                }
                
                // Parse template
                $itemHtml = str_replace(array_keys($replacements), array_values($replacements), $itemTemplate);
                $output .= $itemHtml;
            }
        }
        
        return '<div class="row most-wished-container">' . $output . '</div>';
    }
} catch(\Exception $e) {
    return 'Errore: ' . $e->getMessage();
}

return '<p>' . $_UWLlang['tv_notfound'] . '</p>';