/**
 * AddToWishList
 *
 * Add To WishList
 *
 * @author    Nicola Lambathakis http://www.tattoocms.it/
 * @category  snippet
 * @version   2.8.8
 * @internal  @modx_category UserWishList
 * @lastupdate 20-01-2025 16:47
 */
// 1. INCLUSIONE DIPENDENZE
require_once MODX_BASE_PATH . 'assets/snippets/UserWishList/includes/functions.php';
// 2. GESTIONE LINGUA
$customLang = isset($customLang) ? (string)$customLang : '';
$customLang = preg_replace('/[^a-zA-Z0-9_-]/', '', $customLang);
$customLang = basename($customLang);
$_UWLlang = [];
$langBasePath = MODX_BASE_PATH . 'assets/snippets/UserWishList/lang/';
if ($customLang !== '' && file_exists($langBasePath . 'custom/' . $customLang . '.php')) {
    include ($langBasePath . 'custom/' . $customLang . '.php');
} else {
    include ($langBasePath . 'en.php');
    $managerLang = $modx->config['manager_language'];
    $managerLang = preg_replace('/[^a-zA-Z0-9_-]/', '', $managerLang);
    $managerLang = basename($managerLang);
    if ($managerLang !== 'en' && file_exists($langBasePath . $managerLang . '.php')) {
        include ($langBasePath . $managerLang . '.php');
    }
}
// 3. DEFINIZIONE FUNZIONI
if (!function_exists('UWL_generateWishlistButton')) {
    function UWL_generateWishlistButton($params) {
        $tooltipTitle = $params['disabled'] ? ($params['isLogged'] ? $params['alreadyAlt'] : $params['notLoggedAlt']) : $params['addAlt'];
        return "
        <div class=\"wishlist-container\" data-docid=\"{$params['docid']}\">
            <button type=\"button\" 
                class=\"add-to-wishlist {$params['btnClass']}\" 
                data-docid=\"{$params['docid']}\" 
                data-userid=\"{$params['userId']}\" 
                data-user-tv=\"{$params['userTv']}\"
                data-toggle=\"tooltip\"
                data-placement=\"top\"
                data-add-text='" . htmlspecialchars($params['addText'], ENT_QUOTES) . "'
                data-already-text='" . htmlspecialchars($params['alreadyText'], ENT_QUOTES) . "'
                data-add-alt='" . htmlspecialchars($params['addAlt'], ENT_QUOTES) . "'
                data-already-alt='" . htmlspecialchars($params['alreadyAlt'], ENT_QUOTES) . "'
                data-not-logged-alt='" . htmlspecialchars($params['notLoggedAlt'], ENT_QUOTES) . "'
                title=\"" . htmlspecialchars($tooltipTitle, ENT_QUOTES) . "\"
                aria-label=\"" . htmlspecialchars($tooltipTitle, ENT_QUOTES) . "\"
                id=\"{$params['buttonId']}\"
                " . ($params['disabled'] ? 'disabled' : '') . ">
                {$params['text']}
            </button>
        </div>";
    }
}
// 4. SETUP VARIABILI
$docid = (isset($docid) && (int)$docid > 0) ? (int)$docid : $modx->documentIdentifier;
$EVOuserId = evolutionCMS()->getLoginUserID();
$userId = isset($userId) ? (string)$userId : $EVOuserId;
$userTv = isset($userTv) ? (string)$userTv : 'UserWishList';
$btnClass = isset($btnClass) ? $btnClass : 'btn btn-success';
$btnAddText = isset($btnAddText) ? $btnAddText : $_UWLlang['btnAddText'];
$btnAddAlt = isset($btnAddAlt) ? $btnAddAlt : $_UWLlang['btnAddAlt'];
$btnAlreadyText = isset($btnAlreadyText) ? $btnAlreadyText : $_UWLlang['btnAlreadyText'];
$btnAlreadyAlt = isset($btnAlreadyAlt) ? $btnAlreadyAlt : $_UWLlang['btnAlreadyAlt'];
$ShowToNotLogged = isset($ShowToNotLogged) ? (int)$ShowToNotLogged : 1;
$ToNotLoggedTpl = isset($ToNotLoggedTpl) ? (string)$ToNotLoggedTpl : $_UWLlang['ToNotLoggedTpl'];
$btnNotLoggedAlt = isset($btnNotLoggedAlt) ? $btnNotLoggedAlt : $_UWLlang['btnNotLoggedAlt'];
$showCounter = isset($showCounter) ? (int)$showCounter : 1;
$counterTpl = isset($counterTpl) ? $counterTpl : '<span class="wishlist-count-[+docid+] wishlist-counter ms-2">' . sprintf($_UWLlang['counter_format'], '[+count+]') . '</span>';
$loadToastify = isset($loadToastify) ? (int)$loadToastify : 1;
// Parametri per le notifiche Toast
$toastClose = isset($toastClose) ? $toastClose : 'true';
$toastErrorBg = isset($toastErrorBg) ? $toastErrorBg : 'linear-gradient(to right, #ff5f6d, #ffc371)';
$toastErrorGrav = isset($toastErrorGrav) ? $toastErrorGrav : 'top';
$toastErrorPos = isset($toastErrorPos) ? $toastErrorPos : 'center';
$toastErrorDur = isset($toastErrorDur) ? $toastErrorDur : '3000';
$toastSuccessBg = isset($toastSuccessBg) ? $toastSuccessBg : 'linear-gradient(to right, #00b09b, #96c93d)';
$toastSuccessGrav = isset($toastSuccessGrav) ? $toastSuccessGrav : 'top';
$toastSuccessPos = isset($toastSuccessPos) ? $toastSuccessPos : 'center';
$toastSuccessDur = isset($toastSuccessDur) ? $toastSuccessDur : '5000';
$WishListId = isset($WishListId) ? (int)$WishListId : '';
$added_msg = isset($added_msg) ? $added_msg : $_UWLlang['added_to_wishList'];
// Genera un ID unico per il bottone
$buttonId = ($docid == $modx->documentIdentifier) ? "wishlist-button-main-" . $docid : "wishlist-button-remote-" . $docid;
// Conteggio elementi
$totalUsers = getUserWishlistProductCount($docid, $userTv);
$modx->setPlaceholder('wishlist_count_' . $docid, $totalUsers);
$modx->setPlaceholder('wishlist_count_formatted_' . $docid, str_replace('[+docid+]', $docid, str_replace('[+count+]', $totalUsers, $counterTpl)));
$output = '';
// 5. LOGICA DI CONTROLLO
if (!$EVOuserId || !$docid) {
    // Utente non loggato
    if ($ShowToNotLogged) {
        if ($modx->getChunk($ToNotLoggedTpl)) {
            // Se è un chunk
            $output = $modx->getChunk($ToNotLoggedTpl);
        } else {
            // Usa il valore diretto (dal parametro o dal language file)
            $output = str_replace('class="btn btn-light disabled"', 'class="add-to-wishlist ' . $btnClass . '" 
                data-docid="' . $docid . '" 
                data-userid="' . $userId . '" 
                data-user-tv="' . $userTv . '"
                data-toggle="tooltip"
                data-placement="top"
                data-add-text="' . htmlspecialchars($btnAddText, ENT_QUOTES) . '"
                data-already-text="' . htmlspecialchars($btnAlreadyText, ENT_QUOTES) . '"
                data-add-alt="' . htmlspecialchars($btnAddAlt, ENT_QUOTES) . '"
                data-already-alt="' . htmlspecialchars($btnAlreadyAlt, ENT_QUOTES) . '"
                data-not-logged-alt="' . htmlspecialchars($btnNotLoggedAlt, ENT_QUOTES) . '"
                title="' . htmlspecialchars($btnNotLoggedAlt, ENT_QUOTES) . '"
                aria-label="' . htmlspecialchars($btnNotLoggedAlt, ENT_QUOTES) . '"
                id="' . $buttonId . '"
                disabled', $ToNotLoggedTpl);
        }
    }
} else {
    try {
        // Utente loggato
        $tvValues = \UserManager::getValues(['id' => $userId]);
        $userWishList = isset($tvValues[$userTv]) ? $tvValues[$userTv] : '';
        $wishListIds = $userWishList ? explode(',', $userWishList) : [];
        $isInWishlist = in_array($docid, $wishListIds);
        $output = UWL_generateWishlistButton(['docid' => $docid, 'userId' => $userId, 'userTv' => $userTv, 'btnClass' => $btnClass, 'text' => $isInWishlist ? $btnAlreadyText : $btnAddText, 'addText' => $btnAddText, 'alreadyText' => $btnAlreadyText, 'addAlt' => $btnAddAlt, 'alreadyAlt' => $btnAlreadyAlt, 'notLoggedAlt' => $btnNotLoggedAlt, 'buttonId' => $buttonId, 'disabled' => $isInWishlist, 'isLogged' => true]);
    }
    catch(\Exception $e) {
        $output = UWL_generateWishlistButton(['docid' => $docid, 'userId' => $userId, 'userTv' => $userTv, 'btnClass' => $btnClass, 'text' => $btnAddText, 'addText' => $btnAddText, 'alreadyText' => $btnAlreadyText, 'addAlt' => $btnAddAlt, 'alreadyAlt' => $btnAlreadyAlt, 'notLoggedAlt' => $btnNotLoggedAlt, 'buttonId' => $buttonId, 'disabled' => true, 'isLogged' => true]);
    }
}
// 6. GESTIONE JAVASCRIPT
if (!defined('WISHLIST_SCRIPT_LOADED')) {
    define('WISHLIST_SCRIPT_LOADED', true);
    $wishlistTranslations = json_encode(['error' => $_UWLlang['toast_error'], 'counterUpdateError' => $_UWLlang['counter_update_error'], 'added' => $added_msg, 'alreadyInList' => $_UWLlang['already_in_wishList']]);
    $scriptoutput = '';
    if ($loadToastify) {
        $scriptoutput.= '
        <link rel="stylesheet" type="text/css" href="/assets/snippets/UserWishList/libs/toastify/toastify.min.css">
        <script src="/assets/snippets/UserWishList/libs/toastify/toastify.min.js"></script>';
    }
    $scriptoutput.= '
    <script>
    const wishlistMessages = ' . $wishlistTranslations . ';
    const customLang = "' . $customLang . '";
    
    document.addEventListener("DOMContentLoaded", function() {
        async function updateWishlistCounts(docid) {
            try {
                const button = document.querySelector(`#wishlist-button-main-${docid}, #wishlist-button-remote-${docid}`);
                const response = await fetch("/assets/snippets/UserWishList/includes/ajax/add_handler.php", {
                    method: "POST",
                    headers: {
                        "Content-Type": "application/x-www-form-urlencoded",
                    },
                    body: new URLSearchParams({
                        get_wishlist_count: 1,
                        docid: docid,
                        userTv: button.dataset.userTv
                    })
                });
                
                const data = await response.json();
                if (data.success) {
                    document.querySelectorAll(".wishlist-count-" + data.docid).forEach(counter => {
                        counter.textContent = data.formatted_count;
                    });
                    
                    document.querySelectorAll(`#wishlist-button-main-${data.docid}, #wishlist-button-remote-${data.docid}`).forEach(button => {
                        button.disabled = true;
                        button.innerHTML = button.dataset.alreadyText;
                    });
                }
            } catch (error) {
                console.error(wishlistMessages.counterUpdateError, error);
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
                        userId: button.dataset.userid,
                        userTv: button.dataset.userTv,
                        customLang: customLang,
    					added_msg: "' . addslashes($added_msg) . '"
                    })
                });
                
                const data = await response.json();
                if (data.success) {
    updateWishlistCounts(data.docid);
    
    Toastify({
    	text: data.message,
    	duration: ' . $toastSuccessDur . ',
    	close: ' . $toastClose . ',
    	gravity: "' . $toastSuccessGrav . '",
    	position: "' . $toastSuccessPos . '",
    	' . (!empty($WishListId) ? '
    	onClick: function(){
        	window.location.href = "[~' . $WishListId . '~]";
    	},
    	style: {
        	background: "' . $toastSuccessBg . '",
        	cursor: "pointer"
    	}' : '
    	style: {
        background: "' . $toastSuccessBg . '"
    	}') . '
	}).showToast();
} else {
    Toastify({
        text: data.message || wishlistMessages.error,
        duration: ' . $toastErrorDur . ',
		close: ' . $toastClose . ',
        gravity: "' . $toastErrorGrav . '",
        position: "' . $toastErrorPos . '",
        style: {
            background: "' . $toastErrorBg . '"
        }
    }).showToast();
}
} catch (error) {
    console.error("Errore:", error);
    Toastify({
        text: wishlistMessages.error,
        duration: ' . $toastErrorDur . ',
		close: ' . $toastClose . ',
        gravity: "' . $toastErrorGrav . '",
        position: "' . $toastErrorPos . '",
        style: {
            background: "' . $toastErrorBg . '"
        }
    }).showToast();
}
        }

        // Event Listeners
        document.querySelectorAll(".add-to-wishlist").forEach(button => {
            button.addEventListener("click", () => addToWishlist(button));
        });
    });
    </script>';
    $modx->regClientScript($scriptoutput);
}
// 7. OUTPUT
return $output;
