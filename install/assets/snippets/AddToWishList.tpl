<?php
/**
 * AddToWishList
 *
 * Add To WishList
 * 
 * @author    Nicola Lambathakis http://www.tattoocms.it/
 * @category  snippet
 * @version   1.7
 * @internal  @modx_category UserWishList
 * @lastupdate 28-11-2024 11:20
 */

// Verifica e imposta i parametri
$docid = (isset($docid) && (int)$docid > 0) ? (int)$docid : $modx->documentIdentifier;
$EVOuserId = evolutionCMS()->getLoginUserID();
$userId = isset($userId) ? (string)$userId : $EVOuserId;
$userTv = isset($userTv) ? (string)$userTv : 'UserWishList';
$btnClass = isset($btnClass) ? $btnClass : 'btn btn-success';
$btnAddText = isset($btnAddText) ? $btnAddText : 'Aggiungi a WishList';
$btnAlreadyText = isset($btnAlreadyText) ? $btnAlreadyText : 'Già in WishList';

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
$buttonText = $isInWishlist ? $btnAlreadyText : $btnAddText;
$buttonDisabled = $isInWishlist ? 'disabled' : '';

$output = "
<button type=\"button\" 
    class=\"add-to-wishlist $btnClass\" 
    data-docid=\"$docid\" 
    data-userid=\"$userId\" 
    data-add-text='" . htmlspecialchars($btnAddText, ENT_QUOTES) . "'
    data-already-text='" . htmlspecialchars($btnAlreadyText, ENT_QUOTES) . "'
    id=\"wishlist-button-$docid\"
    $buttonDisabled>
    $buttonText
</button>
";

// JavaScript (una volta sola)
if (!defined('WISHLIST_SCRIPT_LOADED')) {
    define('WISHLIST_SCRIPT_LOADED', true);
    
    $scriptoutput = '
    <link rel="stylesheet" type="text/css" href="https://cdn.jsdelivr.net/npm/toastify-js/src/toastify.min.css">
    <script src="https://cdn.jsdelivr.net/npm/toastify-js"></script>
    <script>
    document.addEventListener("DOMContentLoaded", function() {
        async function addToWishlist(button) {
            if (button.disabled) return;
            
            try {
                const response = await fetch("/assets/snippets/UserWishList/ajax_handler.php", {
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
