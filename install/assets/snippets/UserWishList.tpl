/**
 * UserWishList
 *
 * View the list of products saved with dynamic removal
 *
 * @author    Nicola Lambathakis http://www.tattoocms.it/
 * @category  snippet
 * @version   2.5
 * @internal  @modx_category UserWishList
 * @lastupdate 29-11-2024 19:57
 */

$_UWLlang = array();
include(MODX_BASE_PATH . 'assets/snippets/UserWishList/lang/en.php');
if (file_exists(MODX_BASE_PATH . 'assets/snippets/UserWishList/lang/' . $modx->config['manager_language'] . '.php')) {
    include(MODX_BASE_PATH . 'assets/snippets/UserWishList/lang/' . $modx->config['manager_language'] . '.php');
}
// Funzioni helper per il PDF
function extractPlaceholders($tpl) {
    preg_match_all('/\[\+([^:\+\]]+)/', $tpl, $matches);
    return $matches[1];
}
function parsePlaceholders($tpl, $data) {
    $tpl = str_replace('@CODE:', '', $tpl);
    // Parser per condizionali semplici [+field:ifNotEmpty=`content`+]
    $tpl = preg_replace_callback('/\[\+([^:\+\]]+):ifNotEmpty=`([^`]+)`\+\]/', function ($matches) use ($data) {
        $field = $matches[1];
        $content = $matches[2];
        return !empty($data[$field]) ? $content : '';
    }, $tpl);
    foreach ($data as $key => $value) {
        $tpl = str_replace('[+' . $key . '+]', $value, $tpl);
    }
    return $tpl;
}
$EVOuserId = evolutionCMS()->getLoginUserID();
$userId = isset($userId) ? (string)$userId : $EVOuserId;
$userTv = isset($userTv) ? (string)$userTv : 'UserWishList';
$tpl = isset($tpl) ? $tpl : '@CODE:
    <div class="wishlist-item" id="wishlist-item-[+id+]">
        <h3>[+pagetitle+]</h3>
        <p>[+introtext+]</p>
        [!RemoveFromWishList? &docid=`[+id+]`!]
    </div>';
$showCounter = isset($showCounter) ? (int)$showCounter : 0; // 1 = mostra, 0 = nascondi
$exportFormats = isset($exportFormats) ? explode(',', $exportFormats) : ['pdf', 'csv'];
$showExport = isset($showExport) ? (int)$showExport : 1; // 1 = mostra, 0 = nascondi
// Parametri PDF
$pdfFields = isset($pdfFields) ? explode(',', $pdfFields) : ['pagetitle', 'introtext', 'url'];
$pdf_Title = $_UWLlang['pdf_title'];
$pdfTitle = isset($pdfTitle) ? $pdfTitle : $pdf_Title;
$pdfHeaderTpl = isset($pdfHeaderTpl) ? $pdfHeaderTpl : '@CODE: 
    <h1>[+title+]</h1>
    <p>' . $_UWLlang['exported_on'] . ' [+date+]</p>';
$pdfItemTpl = isset($pdfItemTpl) ? $pdfItemTpl : '@CODE:
    <h2>[+pagetitle+]</h2>
    [+introtext:ifNotEmpty=`<p>[+introtext+]</p>`+]
    [+url:ifNotEmpty=`<p>Link: [+url+]</p>`+]';

// Gestione dell'esportazione
if (isset($_POST['export_wishlist']) && isset($_POST['format'])) {
    try {
        $format = $_POST['format'];
        if (!in_array($format, $exportFormats)) {
            throw new Exception('' . $_UWLlang['format_not_supported'] . '');
        }
        $tvValues = \UserManager::getValues(['id' => $userId]);
        $userWishList = isset($tvValues[$userTv]) ? $tvValues[$userTv] : '';
        if (empty($userWishList)) {
            throw new Exception('' . $_UWLlang['wishList_is_empty'] . '');
        }
        // Ottieni i campi richiesti dai template, escludendo i campi calcolati
        $calculatedFields = ['url', 'title', 'date', 'username']; // campi che aggiungeremo dopo
        $requiredFields = array_unique(array_merge(['id', 'pagetitle'], $pdfFields, extractPlaceholders($pdfHeaderTpl), extractPlaceholders($pdfItemTpl)));
        // Rimuovi i campi calcolati dalla query
        $queryFields = array_diff($requiredFields, $calculatedFields);
        // Prepara i parametri per DocLister
        $params = array('documents' => $userWishList, 'tvList' => isset($tvList) ? $tvList : '', 'selectFields' => implode(',', $queryFields), 'orderBy' => isset($orderBy) ? $orderBy : 'pagetitle ASC', 'api' => implode(',', $queryFields));
        $docs = $modx->runSnippet('DocLister', $params);
        $items = json_decode($docs, true);
        // Aggiungi i campi calcolati dopo aver ottenuto i dati
        foreach ($items as & $item) {
            // Campi calcolati standard
            $item['url'] = $modx->makeUrl($item['id'], '', '', 'full');
            $item['date'] = date('d/m/Y H:i');
            // Se servono per il PDF header
            $item['title'] = $pdfTitle;
            $item['username'] = $modx->getLoginUserName();
            // Qui puoi aggiungere altri campi calcolati se necessario
            
        }
        switch ($format) {
            case 'pdf':
                require_once MODX_BASE_PATH . 'assets/snippets/UserWishList/libs/tcpdf/tcpdf.php';
                class WishListPDF extends TCPDF {
                    public function Header() {
                        $this->SetY(15);
                    }
                    public function Footer() {
                        $this->SetY(-15);
                        $this->SetFont('helvetica', 'I', 8);
                        $this->Cell(0, 10, '' . $_UWLlang["page"] . ' ' . $this->getAliasNumPage() . '/' . $this->getAliasNbPages(), 0, false, 'C');
                    }
                }
                $pdf = new WishListPDF(PDF_PAGE_ORIENTATION, PDF_UNIT, PDF_PAGE_FORMAT, true, 'UTF-8', false);
                $pdf->SetCreator(PDF_CREATOR);
                $pdf->SetAuthor($modx->getLoginUserName());
                $pdf->SetTitle($pdfTitle);
                $pdf->SetFont('helvetica', '', 10);
                $pdf->AddPage();
                // Header
                $headerHtml = parsePlaceholders($pdfHeaderTpl, ['title' => $pdfTitle, 'date' => date('d/m/Y H:i'), 'username' => $modx->getLoginUserName() ]);
                $pdf->writeHTML($headerHtml);
                // Items
                foreach ($items as $item) {
                    $itemHtml = parsePlaceholders($pdfItemTpl, $item);
                    $pdf->writeHTML($itemHtml);
                    $pdf->Ln(5);
                }
                $pdf->Output('wishlist.pdf', 'D');
                exit;
            break;
            case 'csv':
                header('Content-Type: text/csv; charset=utf-8');
                header('Content-Disposition: attachment; filename=wishlist.csv');
                $output = fopen('php://output', 'w');
                fprintf($output, chr(0xEF) . chr(0xBB) . chr(0xBF)); // BOM UTF-8
                fputcsv($output, [$_UWLlang['title'], $_UWLlang['description'], $_UWLlang['URL']]);
                foreach ($items as $item) {
                    fputcsv($output, [$item['pagetitle'], $item['introtext'], $modx->makeUrl($item['id'], '', '', 'full') ]);
                }
                fclose($output);
                exit;
            break;
        }
    }
    catch(Exception $e) {
        return '' . $_UWLlang['export_error'] . ': ' . $e->getMessage();
    }
}
// Visualizzazione normale della lista
try {
    $tvValues = \UserManager::getValues(['id' => $userId]);
    $userWishList = isset($tvValues[$userTv]) ? $tvValues[$userTv] : '';
    // Conteggio elementi
    $totalItems = empty($userWishList) ? 0 : count(explode(',', $userWishList));
    $modx->setPlaceholder('wishlist_total_items', $totalItems);
    if (empty($userWishList)) {
        return '<p>' . $_UWLlang['your_wishList_is_empty'] . '</p>';
    }
    // Prepara i parametri per DocLister
    $params = array('documents' => $userWishList, 'tpl' => $tpl, 'tvPrefix' => '', 'tvList' => isset($tvList) ? $tvList : '', 'selectFields' => isset($selectFields) ? $selectFields : 'id,pagetitle,introtext', 'orderBy' => isset($orderBy) ? $orderBy : 'pagetitle ASC');
    // Form di esportazione
    $exportForm = '';
    if ($showExport) {
        $exportForm = '
    <div class="container">
        <div class="wishlist-export mb-4">
            <form method="post" class="d-flex gap-2 align-items-center">
                <select name="format" class="form-select form-control" style="width: auto;">
                    ' . ($exportFormats ? implode('', array_map(function ($format) {
            return '<option value="' . $format . '">' . strtoupper($format) . '</option>';
        }, $exportFormats)) : '') . '
                </select>
                <button type="submit" name="export_wishlist" class="ml-2 btn btn-primary">
                    ' . $_UWLlang['export_wishList'] . '
                </button>
            </form>
        </div>
    </div>';
    }
    // Counter
	if ($showCounter) {
    $counter = '<div class="wishlist-counter mb-4">' . $_UWLlang['saved_elements'] . ': <span class="badge bg-info">' . $totalItems . '</span></div>';
    }
    // Esegui DocLister
    $output = $modx->runSnippet('DocLister', $params);
    // Aggiungi lo script per la rimozione dinamica e aggiornamento counter
    if (!defined('WISHLIST_REMOVE_HANDLER_LOADED')) {
        define('WISHLIST_REMOVE_HANDLER_LOADED', true);
        $script = '
        <script>
        document.addEventListener("DOMContentLoaded", function() {
            function updateCounter() {
                const items = document.querySelectorAll(".wishlist-item");
                const counter = document.querySelector(".wishlist-counter .badge");
                if (counter) {
                    counter.textContent = items.length;
                }
                
                // Se la lista è vuota
                if (items.length === 0) {
                    document.querySelector(".wishlist-export")?.remove();
                    document.querySelector(".wishlist-counter")?.remove();
                }
            }
            
            // Intercetta il click sui bottoni di rimozione
            document.addEventListener("click", function(e) {
                if (e.target && e.target.classList.contains("remove-from-wishlist")) {
                    const itemId = e.target.dataset.docid;
                    const itemContainer = document.getElementById("wishlist-item-" + itemId);
                    
                    if (itemContainer) {
                        // Aggiungi una classe per l\'animazione di fade out
                        itemContainer.style.transition = "opacity 0.5s ease";
                        itemContainer.style.opacity = "0";
                        
                        // Rimuovi l\'elemento dopo l\'animazione
                        setTimeout(() => {
                            itemContainer.remove();
                            updateCounter();
                            
                            // Se non ci sono più elementi, mostra il messaggio
                            const remainingItems = document.querySelectorAll(".wishlist-item");
                            if (remainingItems.length === 0) {
                                const container = document.querySelector(".wishlist-container");
                                if (container) {
                                    container.innerHTML = "<p>La tua WishList è vuota</p>";
                                }
                            }
                        }, 500);
                    }
                }
            });
        });
        </script>
        <style>
        .wishlist-item {
            opacity: 1;
            transition: opacity 0.5s ease;
        }
        </style>';
        $modx->regClientScript($script);
    }
    return $counter . $exportForm . '<div class="container wishlist-container">' . $output . '</div>';
}
catch(\Exception $e) {
    return '' . $_UWLlang['error'] . ': ' . $e->getMessage();
}