package mmo.petpackage.controller.event
{
   import flash.events.EventDispatcher;
   import mmo.common.eventdispatcher.CommonEvent;
   import mmo.common.eventdispatcher.CommonEventDispatcher;
   import mmo.interfaces.IDispose;
   
   public class PetPackageEventDispatcher extends EventDispatcher implements IDispose
   {
      
      private static var _instance:PetPackageEventDispatcher;
      
      public function PetPackageEventDispatcher()
      {
         super();
      }
      
      public static function get instance() : PetPackageEventDispatcher
      {
         if(_instance == null)
         {
            _instance = new PetPackageEventDispatcher();
         }
         return _instance;
      }
      
      public function openHuanDong() : void
      {
         _instance.dispatchEvent(new PetPackageEvent(PetPackageEvent.ON_OPEN_HUAN_DONG,{}));
      }
      
      public function closeHuanDong() : void
      {
         _instance.dispatchEvent(new PetPackageEvent(PetPackageEvent.ON_CLOSE_HUAN_DONG,{}));
      }
      
      public function closePackagePanel() : void
      {
         _instance.dispatchEvent(new PetPackageEvent(PetPackageEvent.PET_PANEL_CLOSED,{}));
      }
      
      public function openPackageHaiBao() : void
      {
         _instance.dispatchEvent(new PetPackageEvent(PetPackageEvent.ON_OPEN_HAI_BAO,{}));
      }
      
      public function closePackageHaiBao() : void
      {
         _instance.dispatchEvent(new PetPackageEvent(PetPackageEvent.ON_CLOSE_HAI_BAO,{}));
      }
      
      public function onSkinPreMoviePlayFinish() : void
      {
         _instance.dispatchEvent(new PetPackageEvent(PetPackageEvent.ON_SKIN_PRE_MOVIE_FINISH,{}));
      }
      
      public function onOpenCaiDan() : void
      {
         CommonEventDispatcher.instance.dispatchEvent(new CommonEvent(CommonEvent.ON_CAI_DAN_SKIN_OPEN,{}));
      }
      
      public function onClickPackagePanel() : void
      {
      }
      
      public function dispose() : void
      {
         _instance = null;
      }
   }
}

