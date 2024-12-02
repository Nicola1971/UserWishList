/**
 * RemoveFromWishList
 *
 * Remove From WishList
 * 
 * @author    Nicola Lambathakis http://www.tattoocms.it/
 * @category  snippet
 * @version   2.0.3
 * @internal  @modx_category UserWishList
 * @lastupdate 02-12-2024 16:43
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
    include($langBasePath . 'custom/' . $customLang . '.php');
} else {
    // Carica sempre l'inglese come fallback
    include($langBasePath . 'en.php');
    
    // Carica la lingua del manager se disponibile e diversa dall'inglese
    $managerLang = $modx->config['manager_language'];
    $managerLang = preg_replace('/[^a-zA-Z0-9_-]/', '', $managerLang);
    $managerLang = basename($managerLang);
    
    if ($managerLang !== 'en' && file_exists($langBasePath . $managerLang . '.php')) {
        include($langBasePath . $managerLang . '.php');
    }
}

// Verifica e imposta i parametri
$docid = (isset($docid) && (int)$docid > 0) ? (int)$docid : $modx->documentIdentifier;
$EVOuserId = evolutionCMS()->getLoginUserID();
$userId = isset($userId) ? (string)$userId : $EVOuserId;
$userTv = isset($userTv) ? (string)$userTv : 'UserWishList';
$btnClass = isset($btnClass) ? $btnClass : 'btn btn-danger';
$btnRemoveText = isset($btnRemoveText) ? $btnRemoveText : $_UWLlang['btnRemoveText']; //Remove from Wishlist
$btnNotInText = isset($btnNotInText) ? $btnNotInText : $_UWLlang['btnNotInText']; //Not in Wishlist
$btnRemoveAlt = isset($btnRemoveAlt) ? $btnRemoveAlt : $_UWLlang['btnRemoveAlt']; //Rimuovi dalla lista dei desideri
$btnNotInAlt = isset($btnNotInAlt) ? $btnNotInAlt : $_UWLlang['btnNotInAlt']; //Non presente nella lista dei desideri
$loadToastify = isset($loadToastify) ? (int)$loadToastify : 1;

// Verifica WishList
$isInWishlist = false;
try {
    $tvValues = \UserManager::getValues(['id' => $userId]);
    $userWishList = isset($tvValues[$userTv]) ? $tvValues[$userTv] : '';
    $wishListIds = $userWishList ? explode(',', $userWishList) : [];
    $isInWishlist = in_array($docid, $wishListIds);
} catch (\Exception $e) {
    $isInWishlist = false;
}

// Button HTML
$buttonText = $isInWishlist ? $btnRemoveText : $btnNotInText;
$buttonAlt = $isInWishlist ? $btnRemoveAlt : $btnNotInAlt;
$buttonDisabled = !$isInWishlist ? 'disabled' : '';

// Genera un ID unico per il bottone
$buttonId = ($docid == $modx->documentIdentifier) ? 
    "wishlist-remove-button-main-" . $docid : 
    "wishlist-remove-button-remote-" . $docid;

$output = "
<button type=\"button\" 
    class=\"remove-from-wishlist $btnClass\" 
    data-docid=\"$docid\" 
    data-userid=\"$userId\" 
    data-toggle=\"tooltip\"
    data-placement=\"top\"
    data-remove-text='" . htmlspecialchars($btnRemoveText, ENT_QUOTES) . "'
    data-not-in-text='" . htmlspecialchars($btnNotInText, ENT_QUOTES) . "'
    data-remove-alt='" . htmlspecialchars($btnRemoveAlt, ENT_QUOTES) . "'
    data-not-in-alt='" . htmlspecialchars($btnNotInAlt, ENT_QUOTES) . "'
    title=\"" . htmlspecialchars($buttonAlt, ENT_QUOTES) . "\"
    aria-label=\"" . htmlspecialchars($buttonAlt, ENT_QUOTES) . "\"
    id=\"$buttonId\"
    $buttonDisabled>
    $buttonText
</button>
";

// JavaScript (una volta sola)
if (!defined('REMOVE_WISHLIST_SCRIPT_LOADED')) {
    define('REMOVE_WISHLIST_SCRIPT_LOADED', true);
    
    $scriptoutput = '';
    if ($loadToastify) {
        $scriptoutput .= '
        <link rel="stylesheet" type="text/css" href="/assets/snippets/UserWishList/libs/toastify/toastify.min.css">
        <script src="/assets/snippets/UserWishList/libs/toastify/toastify.min.js"></script>';
    }
    
    $scriptoutput .= '
    <script>
    document.addEventListener("DOMContentLoaded", function() {
        async function updateWishlistCounts(docid) {
            try {
                const response = await fetch("/assets/snippets/UserWishList/includes/ajax/remove_handler.php", {
                    method: "POST",
                    headers: {
                        "Content-Type": "application/x-www-form-urlencoded",
                    },
                    body: new URLSearchParams({
                        get_wishlist_count: 1,
                        docid: docid
                    })
                });
                
                const data = await response.json();
                if (data.success) {
                    // Aggiorna TUTTI i contatori per questo docid nella pagina
                    document.querySelectorAll(".wishlist-count-" + data.docid).forEach(counter => {
                        if (counter.classList.contains("wishlist-counter")) {
                            counter.textContent = data.formatted_count;
                        } else {
                            counter.textContent = data.count;
                        }
                    });
                    
                    // Aggiorna sia il bottone di rimozione principale che quelli remoti
                    document.querySelectorAll(`#wishlist-remove-button-main-${data.docid}, #wishlist-remove-button-remote-${data.docid}`).forEach(button => {
                        button.disabled = true;
                        button.innerHTML = button.dataset.notInText;
                        button.title = button.dataset.notInAlt;
                        button.setAttribute("aria-label", button.dataset.notInAlt);
                    });

                    // Aggiorna anche eventuali pulsanti di aggiunta
                    const addButtons = document.querySelectorAll(`#wishlist-button-main-${data.docid}, #wishlist-button-remote-${data.docid}`);
                    addButtons.forEach(button => {
                        button.disabled = false;
                        button.innerHTML = button.dataset.addText;
                        button.title = button.dataset.addAlt;
                        button.setAttribute("aria-label", button.dataset.addAlt);
                    });
                }
            } catch (error) {
                console.error("' . $_UWLlang['counter_update_error'] . ':", error);
            }
        }

        async function removeFromWishlist(button) {
            if (button.disabled) return;
            
            try {
                const response = await fetch("/assets/snippets/UserWishList/includes/ajax/remove_handler.php", {
                    method: "POST",
                    headers: {
                        "Content-Type": "application/x-www-form-urlencoded",
                    },
                    body: new URLSearchParams({
                        remove_from_wishlist: 1,
                        docid: button.dataset.docid,
                        userId: button.dataset.userid
                    })
                });
                
                const data = await response.json();
                
                if (data.success) {
                    // Aggiorna tutti i contatori e i pulsanti per questo prodotto
                    updateWishlistCounts(data.docid);
                    
                    Toastify({
                        text: data.message || "' . $_UWLlang['toast_success'] . '",
                        duration: 3000,
                        gravity: "bottom",
                        position: "left",
                        style: {
                            background: "linear-gradient(to right, #00b09b, #96c93d)",
                        }
                    }).showToast();
                } else {
                    Toastify({
                        text: data.message || "' . $_UWLlang['toast_error'] . '",
                        duration: 3000,
                        gravity: "bottom",
                        position: "left",
                        style: {
                            background: "linear-gradient(to right, #ff5f6d, #ffc371)",
                        }
                    }).showToast();
                }
            } catch (error) {
                console.error("Errore:", error);
                Toastify({
                    text: "' . $_UWLlang['toast_error'] . '",
                    duration: 3000,
                    gravity: "bottom",
                    position: "left",
                    style: {
                        background: "linear-gradient(to right, #ff5f6d, #ffc371)",
                    }
                }).showToast();
            }
        }

        document.querySelectorAll(".remove-from-wishlist").forEach(button => {
            button.addEventListener("click", function() {
                removeFromWishlist(this);
            });
        });
    });
    </script>';

    $modx->regClientScript($scriptoutput);
}

return $output;