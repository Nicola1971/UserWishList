<?php
/**
 * RemoveFromWishList
 *
 * Remove From WishList
 * 
 * @author    Nicola Lambathakis http://www.tattoocms.it/
 * @category  snippet
 * @version   1.6
 * @internal  @modx_category Users
 * @lastupdate 28-11-2024 10:20
 */

// Verifica e imposta i parametri
$docid = (isset($docid) && (int)$docid > 0) ? (int)$docid : $modx->documentIdentifier;
$EVOuserId = evolutionCMS()->getLoginUserID();
$userId = isset($userId) ? (string)$userId : $EVOuserId;
$userTv = isset($userTv) ? (string)$userTv : 'UserWishList';
$btnClass = isset($btnClass) ? $btnClass : 'btn btn-danger';
$btnRemoveText = isset($btnRemoveText) ? $btnRemoveText : 'Rimuovi dalla WishList';
$btnNotInText = isset($btnNotInText) ? $btnNotInText : 'Non in WishList';

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
$buttonDisabled = !$isInWishlist ? 'disabled' : '';

$output = "
<button type=\"button\" 
    class=\"remove-from-wishlist $btnClass\" 
    data-docid=\"$docid\" 
    data-userid=\"$userId\" 
    id=\"wishlist-remove-button-$docid\"
    $buttonDisabled>
    $buttonText
</button>
";

// JavaScript (una volta sola)
if (!defined('REMOVE_WISHLIST_SCRIPT_LOADED')) {
    define('REMOVE_WISHLIST_SCRIPT_LOADED', true);
    
    $scriptoutput = '
    <link rel="stylesheet" type="text/css" href="https://cdn.jsdelivr.net/npm/toastify-js/src/toastify.min.css">
    <script src="https://cdn.jsdelivr.net/npm/toastify-js"></script>
    <script>
    document.addEventListener("DOMContentLoaded", function() {
        async function removeFromWishlist(button) {
            if (button.disabled) return;
            
            try {
                const response = await fetch("/assets/snippets/RemoveFromWishList/ajax_handler.php", {
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
                    const targetButton = document.getElementById("wishlist-remove-button-" + data.docid);
                    if (targetButton) {
                        targetButton.disabled = true;
                        targetButton.textContent = "' . $btnNotInText . '";
                    }
                    
                    // Se esiste il bottone di aggiunta, lo riabilitiamo
                    const addButton = document.getElementById("wishlist-button-" + data.docid);
                    if (addButton) {
                        addButton.disabled = false;
                        addButton.textContent = "Aggiungi a WishList";
                    }
                    
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
                        text: data.message || "Errore durante la rimozione",
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