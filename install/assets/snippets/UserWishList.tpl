<?php
/**
 * UserWishList
 *
 * Visualizza la lista dei prodotti salvati con rimozione dinamica
 * 
 * @author    Nicola Lambathakis http://www.tattoocms.it/
 * @category  snippet
 * @version   1.6
 * @internal  @modx_category UserWishList
 * @lastupdate 28-11-2024 10:20
 */


$EVOuserId = evolutionCMS()->getLoginUserID();
$userId = isset($userId) ? (string)$userId : $EVOuserId;
$userTv = isset($userTv) ? (string)$userTv : 'UserWishList';
$tpl = isset($tpl) ? $tpl : '@CODE:
    <div class="wishlist-item" id="wishlist-item-[+id+]">
        <h3>[+pagetitle+]</h3>
        <p>[+introtext+]</p>
        [!RemoveFromWishList? &docid=`[+id+]`!]
    </div>';

// Ottieni la lista degli ID salvati
try {
    $tvValues = \UserManager::getValues(['id' => $userId]);
    $userWishList = isset($tvValues[$userTv]) ? $tvValues[$userTv] : '';
    
    if (empty($userWishList)) {
        return '<p>La tua WishList è vuota</p>';
    }
    
    // Prepara i parametri per DocLister
    $params = array(
        'documents' => $userWishList,
        'tpl' => $tpl,
        'tvList' => isset($tvList) ? $tvList : '',
        'selectFields' => isset($selectFields) ? $selectFields : 'id,pagetitle,introtext',
        'orderBy' => isset($orderBy) ? $orderBy : 'pagetitle ASC'
    );
    
    // Esegui DocLister
    $output = $modx->runSnippet('DocLister', $params);
    
    // Aggiungi lo script per la rimozione dinamica
    if (!defined('WISHLIST_REMOVE_HANDLER_LOADED')) {
        define('WISHLIST_REMOVE_HANDLER_LOADED', true);
        
        $script = '
        <script>
        document.addEventListener("DOMContentLoaded", function() {
            // Intercetta il click sui bottoni di rimozione
            document.addEventListener("click", function(e) {
                if (e.target && e.target.classList.contains("remove-from-wishlist")) {
                    const itemId = e.target.dataset.docid;
                    const itemContainer = document.getElementById("wishlist-item-" + itemId);
                    
                    if (itemContainer) {
                        // Aggiungi una classe per l\'animazione di fade out
                        itemContainer.style.transition = "opacity 0.5s ease";
                        itemContainer.style.opacity = "0";
                        
                        // Rimuovi l\'elemento dopo l\'animazione
                        setTimeout(() => {
                            itemContainer.remove();
                            
                            // Se non ci sono più elementi, mostra il messaggio
                            const remainingItems = document.querySelectorAll(".wishlist-item");
                            if (remainingItems.length === 0) {
                                const container = document.querySelector(".wishlist-container");
                                if (container) {
                                    container.innerHTML = "<p>La tua WishList è vuota</p>";
                                }
                            }
                        }, 500);
                    }
                }
            });
        });
        </script>
        <style>
        .wishlist-item {
            opacity: 1;
            transition: opacity 0.5s ease;
        }
        </style>';
        
        $modx->regClientScript($script);
    }
    
    return '<div class="wishlist-container">' . $output . '</div>';
    
} catch (\Exception $e) {
    return 'Errore: ' . $e->getMessage();
}