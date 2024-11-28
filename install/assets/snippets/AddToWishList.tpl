<?php
/**
 * AddToWishList
 *
 * Add To WishList
 * 
 * @author    Nicola Lambathakis http://www.tattoocms.it/
 * @category  snippet
 * @version   2.1
 * @internal  @modx_category UserWishList
 * @lastupdate 28-11-2024 20:45
 */

require_once MODX_BASE_PATH . 'assets/snippets/AddToWishList/functions.php';

// Verifica e imposta i parametri
$docid = (isset($docid) && (int)$docid > 0) ? (int)$docid : $modx->documentIdentifier;
$EVOuserId = evolutionCMS()->getLoginUserID();
$userId = isset($userId) ? (string)$userId : $EVOuserId;
$userTv = isset($userTv) ? (string)$userTv : 'UserWishList';
$btnClass = isset($btnClass) ? $btnClass : 'btn btn-success';
$btnAddText = isset($btnAddText) ? $btnAddText : 'Aggiungi a WishList';
$btnAlreadyText = isset($btnAlreadyText) ? $btnAlreadyText : 'Già in WishList';
$btnAddAlt = isset($btnAddAlt) ? $btnAddAlt : 'Aggiungi alla lista dei desideri';
$btnAlreadyAlt = isset($btnAlreadyAlt) ? $btnAlreadyAlt : 'Elemento già presente nella lista dei desideri';
$ShowToNotLogged = isset($ShowToNotLogged) ? (int)$ShowToNotLogged : 1;
$ToNotLoggedTpl = isset($ToNotLoggedTpl) ? $ToNotLoggedTpl : '<p class="text-muted">Effettua il login per aggiungere alla WishList</p>';
$showCounter = isset($showCounter) ? (int)$showCounter : 1;
$counterTpl = isset($counterTpl) ? $counterTpl : '<span class="wishlist-count-[+docid+] wishlist-counter ms-2">([+count+])</span>';

// Ottieni il numero di utenti che hanno il prodotto nella loro wishlist
$totalUsers = getUserWishlistProductCount($docid, $userTv);

// Set placeholders per il conteggio
$modx->setPlaceholder('wishlist_count', $totalUsers);
$modx->setPlaceholder('wishlist_count_formatted', str_replace('[+docid+]', $docid, str_replace('[+count+]', $totalUsers, $counterTpl)));

// Verifica se l'utente è loggato
if (!$EVOuserId || !$docid) {
    // Utente non loggato
    if ($ShowToNotLogged) {
        if (substr($ToNotLoggedTpl, 0, 1) === '@') {
            $chunkName = substr($ToNotLoggedTpl, 1);
            return $modx->getChunk($chunkName);
        }
        return $ToNotLoggedTpl;
    }
    return '';
}

try {
    // Otteniamo i valori correnti dell'utente
    $tvValues = \UserManager::getValues(['id' => $userId]);
    
    // Verifica WishList
    $userWishList = isset($tvValues[$userTv]) ? $tvValues[$userTv] : '';
    $wishListIds = $userWishList ? explode(',', $userWishList) : [];
    $isInWishlist = in_array($docid, $wishListIds);
    
    // Ottieni il conteggio totale
    $totalCount = count($wishListIds);
    
    // Set placeholders per il conteggio
    $modx->setPlaceholder('wishlist_count', $totalCount);
    $modx->setPlaceholder('wishlist_count_formatted', str_replace('[+docid+]', $docid, str_replace('[+count+]', $totalCount, $counterTpl)));
    
} catch (\Exception $e) {
    $isInWishlist = false;
    $totalCount = 0;
    $modx->setPlaceholder('wishlist_count', 0);
    $modx->setPlaceholder('wishlist_count_formatted', str_replace('[+docid+]', $docid, str_replace('[+count+]', 0, $counterTpl)));
    
} catch (\Exception $e) {
    $isInWishlist = false;
    $totalCount = 0;
    // In caso di errore, mostra il messaggio per utenti non loggati
    if ($ShowToNotLogged) {
        if (substr($ToNotLoggedTpl, 0, 1) === '@') {
            $chunkName = substr($ToNotLoggedTpl, 1);
            return $modx->getChunk($chunkName);
        }
        return $ToNotLoggedTpl;
    }
    return '';
}
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
        title=\"" . htmlspecialchars($buttonAlt, ENT_QUOTES) . "\"
        aria-label=\"" . htmlspecialchars($buttonAlt, ENT_QUOTES) . "\"
        id=\"wishlist-button-$docid\"
        $buttonDisabled>
        $buttonText
    </button>
</div>
";

// JavaScript (una volta sola)
if (!defined('WISHLIST_SCRIPT_LOADED')) {
    define('WISHLIST_SCRIPT_LOADED', true);
    
    $scriptoutput = '
    <link rel="stylesheet" type="text/css" href="https://cdn.jsdelivr.net/npm/toastify-js/src/toastify.min.css">
    <script src="https://cdn.jsdelivr.net/npm/toastify-js"></script>
    <script>
    document.addEventListener("DOMContentLoaded", function() {
        async function updateWishlistCount(docid) {
            try {
                const response = await fetch("/assets/snippets/AddToWishList/ajax_handler.php", {
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
                        counter.textContent = data.count;
                    });
                }
            } catch (error) {
                console.error("Errore nell\'aggiornamento del contatore:", error);
            }
        }

        async function addToWishlist(button) {
            if (button.disabled) return;
            
            try {
                const response = await fetch("/assets/snippets/AddToWishList/ajax_handler.php", {
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