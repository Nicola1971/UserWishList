/**
 * RemoveFromWishList
 *
 * Remove items from WishList
 * 
 * @author    Nicola Lambathakis http://www.tattoocms.it/
 * @category  snippet
 * @version   1.9
 * @internal  @modx_category UserWishList
 * @lastupdate 29-11-2024 13:00
 */

// Verifica e imposta i parametri
$docid = (isset($docid) && (int)$docid > 0) ? (int)$docid : $modx->documentIdentifier;
$EVOuserId = evolutionCMS()->getLoginUserID();
$userId = isset($userId) ? (string)$userId : $EVOuserId;
$userTv = isset($userTv) ? (string)$userTv : 'UserWishList';
$btnClass = isset($btnClass) ? $btnClass : 'btn btn-danger';
$btnRemoveText = isset($btnRemoveText) ? $btnRemoveText : 'Rimuovi dalla WishList';
$btnNotInText = isset($btnNotInText) ? $btnNotInText : 'Non in WishList';
$loadToastify = isset($loadToastify) ? (int)$loadToastify : 1; // 1 = carica, 0 = non caricare

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
    data-remove-text='" . htmlspecialchars($btnRemoveText, ENT_QUOTES) . "'
    data-not-in-text='" . htmlspecialchars($btnNotInText, ENT_QUOTES) . "'
    id=\"wishlist-remove-button-$docid\"
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
    <link rel="stylesheet" type="text/css" href="/assets/snippets/UserWishList/libs/toastify/toastify.min.css">
	<script src="/assets/snippets/UserWishList/libs/toastify/toastify.min.js"></script>
    <script>
    document.addEventListener("DOMContentLoaded", function() {
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
                    const targetButton = document.getElementById("wishlist-remove-button-" + data.docid);
                    if (targetButton) {
                        targetButton.disabled = true;
                        targetButton.innerHTML = targetButton.dataset.notInText;
                    }
                    
                    // Se esiste il bottone di aggiunta, lo riabilitiamo
                    const addButton = document.getElementById("wishlist-button-" + data.docid);
                    if (addButton) {
                        addButton.disabled = false;
                        // Usa il testo salvato nel data attribute se disponibile
                        addButton.innerHTML = addButton.dataset.addText || "Aggiungi a WishList";
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