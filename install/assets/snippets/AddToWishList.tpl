<?php
/**
 * AddToWishList
 *
 * Add To WishList
 * 
 * @author    Nicola Lambathakis http://www.tattoocms.it/
 * @category  snippet
 * @version   1.2
 * @internal  @modx_category Users
 * @lastupdate 27-11-2024 18:20
 */

// Verifica e imposta i parametri
$docid = (isset($docid) && (int)$docid > 0) ? (int)$docid : $modx->documentIdentifier;
$EVOuserId = evolutionCMS()->getLoginUserID();
$userId = isset($userId) ? (string)$userId : $EVOuserId;
$userTv = isset($userTv) ? (string)$userTv : 'UserWishList';
$btnClass = isset($btnClass) ? $btnClass : 'btn btn-success';
$btnAddText = isset($btnAddText) ? $btnAddText : 'Aggiungi a WishList';
$btnAlreadyText = isset($btnAlreadyText) ? $btnAlreadyText : 'Già in WishList';
$jQuery = isset($jQuery) ? $jQuery : '1';

// Gestione richiesta AJAX
if (isset($_SERVER['HTTP_X_REQUESTED_WITH']) && strtolower($_SERVER['HTTP_X_REQUESTED_WITH']) == 'xmlhttprequest') {
    header('Content-Type: application/json');
    
    if (isset($_POST['add_to_wishlist'])) {
        try {
            $tvValues = \UserManager::getValues(['id' => $userId]);
            
            $userWishList = isset($tvValues[$userTv]) ? $tvValues[$userTv] : '';
            $wishListIds = $userWishList ? explode(',', $userWishList) : [];
            
            if (!in_array($docid, $wishListIds)) {
                $wishListIds[] = $docid;
                $userWishList = implode(',', $wishListIds);
                
                $userData = ['id' => $userId, $userTv => $userWishList];
                \UserManager::saveValues($userData);
                
                die(json_encode(['success' => true, 'message' => 'Aggiunto alla WishList']));
            }
            
            die(json_encode(['success' => false, 'message' => 'Salvato nella WishList']));
        } catch (\Exception $e) {
            die(json_encode(['success' => false, 'message' => $e->getMessage()]));
        }
    }
    exit;
}

// Verifica se l'ID del documento è già nella UserWishList
$isInWishlist = false;
try {
    $tvValues = \UserManager::getValues(['id' => $userId]);
    $userWishList = isset($tvValues[$userTv]) ? $tvValues[$userTv] : '';
    $wishListIds = $userWishList ? explode(',', $userWishList) : [];
    $isInWishlist = in_array($docid, $wishListIds);
} catch (\Exception $e) {
    // Gestione dell'errore nel caso UserManager non funzioni correttamente
    $isInWishlist = false;
}

// Genera il pulsante con il controllo PHP
$buttonText = $isInWishlist ? $btnAlreadyText : $btnAddText;
$buttonDisabled = $isInWishlist ? 'disabled' : '';

$output = "
<button type=\"button\" 
    class=\"add-to-wishlist $btnClass\" 
    data-docid=\"$docid\" 
    data-userid=\"$userId\" 
    $buttonDisabled>
    $buttonText
</button>
";

// Aggiungi lo script JavaScript necessario
$scriptoutput = '';
if ($jQuery == "1" && !$modx->regClientScript('jquery')) {
    $scriptoutput .= '<script src="https://code.jquery.com/jquery-3.6.0.min.js"></script>';
}

$scriptoutput .= "
<script src=\"https://cdn.jsdelivr.net/npm/toastify-js\"></script>
<script>
$(document).ready(function() {
    $('.add-to-wishlist').on('click', function() {
        var button = $(this);
        $.ajax({
            url: document.location.href,
            method: 'POST',
            data: {
                add_to_wishlist: 1,
                docid: button.data('docid'),
                userId: button.data('userid')
            },
            dataType: 'json',
            success: function(response) {
                if (response.success) {
                    button.prop('disabled', true).text('$btnAlreadyText');
                    Toastify({
                        text: 'Aggiunto alla WishList',
                        duration: 3000,
                        gravity: 'bottom',
                        position: 'left',
                        backgroundColor: 'linear-gradient(to right, #00b09b, #96c93d)'
                    }).showToast();
                } else {
                    alert(response.message);
                }
            }
        });
    });
});
</script>
";

// Registra lo script JavaScript
$modx->regClientScript($scriptoutput);

// Ritorna l'output del pulsante
return $output;
