/**
 * AddToWishList
 *
 * Add items to the WishList
 * 
 * @author    Nicola Lambathakis http://www.tattoocms.it/
 * @category  snippet
 * @version   2.5
 * @internal  @modx_category UserWishList
 * @lastupdate 29-11-2024 12:55
 */

require_once MODX_BASE_PATH . 'assets/snippets/UserWishList/includes/functions.php';

// Verifica e imposta i parametri
$docid = (isset($docid) && (int)$docid > 0) ? (int)$docid : $modx->documentIdentifier;
$EVOuserId = evolutionCMS()->getLoginUserID();
$userId = isset($userId) ? (string)$userId : $EVOuserId;
$userTv = isset($userTv) ? (string)$userTv : 'UserWishList';
$btnClass = isset($btnClass) ? $btnClass : 'btn btn-success';
$btnAddText = isset($btnAddText) ? $btnAddText : 'Aggiungi a WishList';
$btnAddAlt = isset($btnAddAlt) ? $btnAddAlt : 'Aggiungi alla lista dei desideri';
$btnAlreadyText = isset($btnAlreadyText) ? $btnAlreadyText : 'Già in WishList';
$btnAlreadyAlt = isset($btnAlreadyAlt) ? $btnAlreadyAlt : 'Elemento già presente nella lista dei desideri';
$ShowToNotLogged = isset($ShowToNotLogged) ? (int)$ShowToNotLogged : 1;
$ToNotLoggedTpl = isset($ToNotLoggedTpl) ? $ToNotLoggedTpl : '<p class="text-muted">Effettua il login per aggiungere alla WishList</p>';
$btnNotLoggedAlt = isset($btnNotLoggedAlt) ? $btnNotLoggedAlt : 'Effettua il login per aggiungere alla lista dei desideri';
$showCounter = isset($showCounter) ? (int)$showCounter : 1;
$counterTpl = isset($counterTpl) ? $counterTpl : '<span class="wishlist-count-[+docid+] wishlist-counter ms-2">([+count+])</span>';
$loadToastify = isset($loadToastify) ? (int)$loadToastify : 1; // 1 = carica, 0 = non caricare

// Ottieni il numero di utenti che hanno il prodotto nella loro wishlist
$totalUsers = getUserWishlistProductCount($docid, $userTv);

// Set placeholders per il conteggio
$modx->setPlaceholder('wishlist_count', $totalUsers);
$modx->setPlaceholder('wishlist_count_formatted', str_replace('[+docid+]', $docid, str_replace('[+count+]', $totalUsers, $counterTpl)));

$output = '';
// Verifica se l'utente è loggato
if (!$EVOuserId || !$docid) {
    // Utente non loggato
    if ($ShowToNotLogged) {
        // Se vogliamo mostrare il bottone anche agli utenti non loggati
        if (substr($ToNotLoggedTpl, 0, 1) === '@') {
            $chunkName = substr($ToNotLoggedTpl, 1);
            $output = $modx->getChunk($chunkName);
        } else {
            $buttonText = $btnAddText;
            $buttonAlt = $btnNotLoggedAlt; // Usiamo il testo specifico per non loggati
            $buttonDisabled = 'disabled';
            
            $output = "
            <div class=\"wishlist-container\" data-docid=\"$docid\">
                <button type=\"button\" 
                    class=\"add-to-wishlist $btnClass\" 
                    data-docid=\"$docid\" 
                    data-userid=\"$userId\" 
                    data-add-text='" . htmlspecialchars($btnAddText, ENT_QUOTES) . "'
                    data-already-text='" . htmlspecialchars($btnAlreadyText, ENT_QUOTES) . "'
                    data-add-alt='" . htmlspecialchars($btnAddAlt, ENT_QUOTES) . "'
                    data-already-alt='" . htmlspecialchars($btnAlreadyAlt, ENT_QUOTES) . "'
                    data-not-logged-alt='" . htmlspecialchars($btnNotLoggedAlt, ENT_QUOTES) . "'
                    title=\"" . htmlspecialchars($buttonAlt, ENT_QUOTES) . "\"
                    aria-label=\"" . htmlspecialchars($buttonAlt, ENT_QUOTES) . "\"
                    id=\"wishlist-button-$docid\"
                    $buttonDisabled>
                    $buttonText
                </button>
            </div>";
        }
    }
} else {
    try {
        // Otteniamo i valori correnti dell'utente
        $tvValues = \UserManager::getValues(['id' => $userId]);
        
        // Verifica WishList
        $userWishList = isset($tvValues[$userTv]) ? $tvValues[$userTv] : '';
        $wishListIds = $userWishList ? explode(',', $userWishList) : [];
        $isInWishlist = in_array($docid, $wishListIds);
        
        // Button HTML
        $buttonText = $isInWishlist ? $btnAlreadyText : $btnAddText;
        $buttonAlt = $isInWishlist ? $btnAlreadyAlt : $btnAddAlt;
        $buttonDisabled = $isInWishlist ? 'disabled' : '';
        
        $output = "
        <div class=\"wishlist-container\" data-docid=\"$docid\">
            <button type=\"button\" 
                class=\"add-to-wishlist $btnClass\" 
                data-docid=\"$docid\" 
                data-userid=\"$userId\" 
                data-add-text='" . htmlspecialchars($btnAddText, ENT_QUOTES) . "'
                data-already-text='" . htmlspecialchars($btnAlreadyText, ENT_QUOTES) . "'
                data-add-alt='" . htmlspecialchars($btnAddAlt, ENT_QUOTES) . "'
                data-already-alt='" . htmlspecialchars($btnAlreadyAlt, ENT_QUOTES) . "'
                data-not-logged-alt='" . htmlspecialchars($btnNotLoggedAlt, ENT_QUOTES) . "'
                title=\"" . htmlspecialchars($buttonAlt, ENT_QUOTES) . "\"
                aria-label=\"" . htmlspecialchars($buttonAlt, ENT_QUOTES) . "\"
                id=\"wishlist-button-$docid\"
                $buttonDisabled>
                $buttonText
            </button>
        </div>";
        
    } catch (\Exception $e) {
        $isInWishlist = false;
        $buttonText = $btnAddText;
        $buttonAlt = $btnNotLoggedAlt;
        $buttonDisabled = 'disabled';
        
        $output = "
        <div class=\"wishlist-container\" data-docid=\"$docid\">
            <button type=\"button\" 
                class=\"add-to-wishlist $btnClass\" 
                data-docid=\"$docid\" 
                data-userid=\"$userId\" 
                data-add-text='" . htmlspecialchars($btnAddText, ENT_QUOTES) . "'
                data-already-text='" . htmlspecialchars($btnAlreadyText, ENT_QUOTES) . "'
                data-add-alt='" . htmlspecialchars($btnAddAlt, ENT_QUOTES) . "'
                data-already-alt='" . htmlspecialchars($btnAlreadyAlt, ENT_QUOTES) . "'
                data-not-logged-alt='" . htmlspecialchars($btnNotLoggedAlt, ENT_QUOTES) . "'
                title=\"" . htmlspecialchars($buttonAlt, ENT_QUOTES) . "\"
                aria-label=\"" . htmlspecialchars($buttonAlt, ENT_QUOTES) . "\"
                id=\"wishlist-button-$docid\"
                $buttonDisabled>
                $buttonText
            </button>
        </div>";
    }
}

// JavaScript (una volta sola)
if (!defined('WISHLIST_SCRIPT_LOADED')) {
    define('WISHLIST_SCRIPT_LOADED', true);
    
    $scriptoutput = '';
    if ($loadToastify) {
        $scriptoutput .= '
        <link rel="stylesheet" type="text/css" href="/assets/snippets/UserWishList/libs/toastify/toastify.min.css">
        <script src="/assets/snippets/UserWishList/libs/toastify/toastify.min.js"></script>';
    }
    
    $scriptoutput .= '
    <script>
    document.addEventListener("DOMContentLoaded", function() {
        async function updateWishlistCount(docid) {
            try {
                const response = await fetch("/assets/snippets/UserWishList/includes/ajax/add_handler.php", {
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
                    const containers = document.querySelectorAll(".wishlist-count-" + data.docid);
                    containers.forEach(counter => {
                        counter.textContent = "(" + data.count + ")";
                    });
                }
            } catch (error) {
                console.error("Errore nell\'aggiornamento del contatore:", error);
            }
        }

        async function addToWishlist(button) {
            if (button.disabled) return;
            
            try {
                const response = await fetch("/assets/snippets/UserWishList/includes/ajax/add_handler.php", {
                    method: "POST",
                    headers: {
                        "Content-Type": "application/x-www-form-urlencoded",
                    },
                    body: new URLSearchParams({
                        add_to_wishlist: 1,
                        docid: button.dataset.docid,
                        userId: button.dataset.userid
                    })
                });
                
                const data = await response.json();
                
                if (data.success) {
                    const targetButton = document.getElementById("wishlist-button-" + data.docid);
                    if (targetButton) {
                        targetButton.disabled = true;
                        targetButton.innerHTML = targetButton.dataset.alreadyText;
                        targetButton.title = targetButton.dataset.alreadyAlt;
                        targetButton.setAttribute("aria-label", targetButton.dataset.alreadyAlt);
                    }
                    
                    // Aggiorna il contatore
                    updateWishlistCount(data.docid);
                    
                    Toastify({
                        text: data.message,
                        duration: 3000,
                        gravity: "bottom",
                        position: "left",
                        style: {
                            background: "linear-gradient(to right, #00b09b, #96c93d)",
                        }
                    }).showToast();
                } else {
                    Toastify({
                        text: data.message || "Errore durante l\'aggiunta",
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
                    text: "Errore durante l\'operazione",
                    duration: 3000,
                    gravity: "bottom",
                    position: "left",
                    style: {
                        background: "linear-gradient(to right, #ff5f6d, #ffc371)",
                    }
                }).showToast();
            }
        }

        document.querySelectorAll(".add-to-wishlist").forEach(button => {
            button.addEventListener("click", function() {
                addToWishlist(this);
            });
        });
    });
    </script>';

    $modx->regClientScript($scriptoutput);
}

return $output;