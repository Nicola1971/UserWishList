/**
 * UserWishList
 *
 * View the list of products saved with dynamic removal
 *
 * @author    Nicola Lambathakis http://www.tattoocms.it/
 * @category  snippet
 * @version   2.6.2
 * @internal  @modx_category UserWishList
 * @lastupdate 10-12-2024 09:56
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
            data-remove-alt='" . htmlspecialchars($params['removeAlt'], ENT_QUOTES) . "'
            title=\"" . htmlspecialchars($params['removeAlt'], ENT_QUOTES) . "\"
            aria-label=\"" . htmlspecialchars($params['removeAlt'], ENT_QUOTES) . "\">
            {$params['removeText']}
        </button>";
    }
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
$showCounter = isset($showCounter) ? (int)$showCounter : 0; // 1 = mostra, 0 = nascondi

// Visualizzazione normale della lista
try {
    $tvValues = \UserManager::getValues(['id' => $userId]);
    $userWishList = isset($tvValues[$userTv]) ? $tvValues[$userTv] : '';
    // Conteggio elementi
    $totalItems = empty($userWishList) ? 0 : count(explode(',', $userWishList));
    $modx->setPlaceholder('wishlist_total_items', '<span class="wishlist-total-items">'.$totalItems.'</span>');
    if (empty($userWishList)) {
        return '<p>' . $_UWLlang['your_wishList_is_empty'] . '</p>';
    }
    // Prepara i parametri per DocLister
    $params = array('documents' => $userWishList, 'tpl' => $tpl, 'tvPrefix' => '', 'tvList' => isset($tvList) ? $tvList : '', 'summary' => isset($summary) ? $summary : 'notags,len:300', 'orderBy' => isset($orderBy) ? $orderBy : 'pagetitle ASC', 'prepare' => function ($data, $modx, $DL) use ($userId, $userTv, $btnRemoveClass, $btnRemoveText, $btnRemoveAlt) {
        // Genera il bottone per questo elemento
        $data['wishlist_remove_button'] = UWL_generateRemoveButton(['docid' => $data['id'], 'userId' => $userId, 'userTv' => $userTv, 'btnClass' => $btnRemoveClass, 'removeText' => $btnRemoveText, 'removeAlt' => $btnRemoveAlt]);
        return $data;
    });

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
        // Aggiorna il placeholder wishlist_total_items
    	const totalCounters = document.querySelectorAll(".wishlist-total-items");
    	totalCounters.forEach(counter => {
        counter.textContent = items.length;
    	});
        if (items.length === 0) {
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
    return $counter . '<div class="' . $outerClass . ' wishlist-container">' . $output . '</div>';
}
catch(\Exception $e) {
    return '' . $_UWLlang['error'] . ': ' . $e->getMessage();
}