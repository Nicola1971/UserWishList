<?php
/**
 * UserWishList
 *
 * View the list of products saved with dynamic removal
 *
 * @author    Nicola Lambathakis http://www.tattoocms.it/
 * @category  snippet
 * @version   2.6
 * @internal  @modx_category UserWishList
 * @lastupdate 07-12-2024 10:50
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
// Funzione helper per il bottone di rimozione
if (!function_exists('UWL_generateRemoveButton')) {
    function UWL_generateRemoveButton($params) {
        return "
        <button type=\"button\" 
            class=\"remove-from-wishlist {$params['btnClass']}\" 
            data-docid=\"{$params['docid']}\" 
            data-userid=\"{$params['userId']}\" 
            data-user-tv=\"{$params['userTv']}\"
            data-toggle=\"tooltip\"
            data-placement=\"top\"
            data-remove-text='" . htmlspecialchars($params['removeText'], ENT_QUOTES) . "'
            data-not-in-text='" . htmlspecialchars($params['notInText'], ENT_QUOTES) . "'
            data-remove-alt='" . htmlspecialchars($params['removeAlt'], ENT_QUOTES) . "'
            data-not-in-alt='" . htmlspecialchars($params['notInAlt'], ENT_QUOTES) . "'
            title=\"" . htmlspecialchars($params['removeAlt'], ENT_QUOTES) . "\"
            aria-label=\"" . htmlspecialchars($params['removeAlt'], ENT_QUOTES) . "\">
            {$params['removeText']}
        </button>";
    }
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
$loadToastify = isset($loadToastify) ? (int)$loadToastify : 1;
$outerClass = isset($outerClass) ? $outerClass : 'container';
$tpl = isset($tpl) ? $tpl : '@CODE:
    <div class="wishlist-item" id="wishlist-item-[+id+]">
        <h3>[+pagetitle+]</h3>
        <p>[+introtext+]</p>
        [+wishlist_remove_button+]
    </div>';
// Parametri per il bottone di rimozione
$btnRemoveClass = isset($btnRemoveClass) ? $btnRemoveClass : 'btn btn-danger';
$btnRemoveText = isset($btnRemoveText) ? $btnRemoveText : $_UWLlang['btnRemoveText'];
$btnRemoveAlt = isset($btnRemoveAlt) ? $btnRemoveAlt : $_UWLlang['btnRemoveAlt'];
$btnNotInText = isset($btnNotInText) ? $btnNotInText : $_UWLlang['btnNotInText'];
$btnNotInAlt = isset($btnNotInAlt) ? $btnNotInAlt : $_UWLlang['btnNotInAlt'];
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
        $modx->logEvent(0, 1, "Required Fields: " . print_r($requiredFields, true), 'WishList Export Debug - Fields');
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
        $params = array('documents' => $userWishList, 'tvList' => isset($tvList) ? $tvList : '', 'selectFields' => 'id,pagetitle,introtext', // Specifichiamo esplicitamente i campi
        'orderBy' => isset($orderBy) ? $orderBy : 'pagetitle ASC', 'api' => 'id,pagetitle,introtext', // Stessi campi in api
        'debug' => 1, 'prepare' => function ($data, $modx, $DL) use ($userId, $userTv, $btnRemoveClass, $btnRemoveText, $btnRemoveAlt, $btnNotInText, $btnNotInAlt) {
            // Genera il bottone per questo elemento
            $data['wishlist_remove_button'] = UWL_generateRemoveButton(['docid' => $data['id'], 'userId' => $userId, 'userTv' => $userTv, 'btnClass' => $btnRemoveClass, 'removeText' => $btnRemoveText, 'notInText' => $btnNotInText, 'removeAlt' => $btnRemoveAlt, 'notInAlt' => $btnNotInAlt]);
            return $data;
        });
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
    $params = array('documents' => $userWishList, 'tpl' => $tpl, 'tvPrefix' => '', 'tvList' => isset($tvList) ? $tvList : '', 'selectFields' => isset($selectFields) ? $selectFields : 'id,pagetitle,introtext', 'orderBy' => isset($orderBy) ? $orderBy : 'pagetitle ASC', 'prepare' => function ($data, $modx, $DL) use ($userId, $userTv, $btnRemoveClass, $btnRemoveText, $btnRemoveAlt, $btnNotInText, $btnNotInAlt) {
        // Genera il bottone per questo elemento
        $data['wishlist_remove_button'] = UWL_generateRemoveButton(['docid' => $data['id'], 'userId' => $userId, 'userTv' => $userTv, 'btnClass' => $btnRemoveClass, 'removeText' => $btnRemoveText, 'notInText' => $btnNotInText, 'removeAlt' => $btnRemoveAlt, 'notInAlt' => $btnNotInAlt]);
        return $data;
    });
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
    $counter = '';
    if ($showCounter) {
        $counter = '<div class="wishlist-counter mb-4">' . $_UWLlang['saved_elements'] . ': <span class="badge bg-info">' . $totalItems . '</span></div>';
    }
    // Esegui DocLister
    $output = $modx->runSnippet('DocLister', $params);
    // Aggiungi lo script per la rimozione dinamica e aggiornamento counter
    if (!defined('WISHLIST_REMOVE_HANDLER_LOADED')) {
        define('WISHLIST_REMOVE_HANDLER_LOADED', true);
        // Prepariamo solo le traduzioni necessarie per UserWishList
        $wishlistTranslations = json_encode(['removed' => $_UWLlang['removed_from_wishList'], 'error' => $_UWLlang['error'], 'empty' => $_UWLlang['your_wishList_is_empty']]);
        $script = '
        <script>
		const wishlistMessages = ' . $wishlistTranslations . ';
        document.addEventListener("DOMContentLoaded", function() {
    function updateCounter() {
        const items = document.querySelectorAll(".wishlist-item");
        const counter = document.querySelector(".wishlist-counter .badge");
        if (counter) {
            counter.textContent = items.length;
        }
        
        if (items.length === 0) {
            document.querySelector(".wishlist-export")?.remove();
            document.querySelector(".wishlist-counter")?.remove();
            const container = document.querySelector(".wishlist-container");
            if (container) {
                container.innerHTML = wishlistMessages.empty;
            }
        }
    }

    async function removeFromWishlist(button) {
        const itemId = button.dataset.docid;
        const itemContainer = document.getElementById("wishlist-item-" + itemId);
        
        if (!itemContainer) return;

        try {
            const response = await fetch("/assets/snippets/UserWishList/includes/ajax/remove_handler.php", {
                method: "POST",
                headers: {
                    "Content-Type": "application/x-www-form-urlencoded",
                },
                body: new URLSearchParams({
                    remove_from_wishlist: 1,
                    docid: button.dataset.docid,
                    userId: button.dataset.userid,
                    userTv: button.dataset.userTv
                })
            });

            const data = await response.json();
            
            if (data.success) {
                itemContainer.style.transition = "opacity 0.5s ease";
                itemContainer.style.opacity = "0";
                
                setTimeout(() => {
                    itemContainer.remove();
                    updateCounter();
                }, 500);

                if (typeof Toastify !== "undefined") {
                    Toastify({
                        text: wishlistMessages.removed,
                        duration: 3000,
                        gravity: "bottom",
                        position: "left",
                        style: {
                            background: "linear-gradient(to right, #00b09b, #96c93d)",
                        }
                    }).showToast();
                }
            } else {
                if (typeof Toastify !== "undefined") {
                    Toastify({
                        text: wishlistMessages.error,
                        duration: 3000,
                        gravity: "bottom",
                        position: "left",
                        style: {
                            background: "linear-gradient(to right, #ff5f6d, #ffc371)",
                        }
                    }).showToast();
                }
            }
        } catch (error) {
            console.error("Error:", error);
            if (typeof Toastify !== "undefined") {
                Toastify({
                    text: wishlistMessages.error,
                    duration: 3000,
                    gravity: "bottom",
                    position: "left",
                    style: {
                        background: "linear-gradient(to right, #ff5f6d, #ffc371)",
                    }
                }).showToast();
            }
        }
    }
    
    document.addEventListener("click", function(e) {
        if (e.target && e.target.classList.contains("remove-from-wishlist")) {
            removeFromWishlist(e.target);
        }
    });
});
</script>';
        // Carica Toastify se necessario
        if ($loadToastify) {
            $modx->regClientCSS("/assets/snippets/UserWishList/libs/toastify/toastify.min.css");
            $modx->regClientScript("/assets/snippets/UserWishList/libs/toastify/toastify.min.js");
        }
        $modx->regClientScript($script);
    }
    return $counter . $exportForm . '<div class="' . $outerClass . ' wishlist-container">' . $output . '</div>';
}
catch(\Exception $e) {
    return '' . $_UWLlang['error'] . ': ' . $e->getMessage();
}