package mmo.petfightnew.common.fightcontroller.fightinfopanel.config
{
   import fl.containers.ScrollPane;
   import flash.system.ApplicationDomain;
   import flash.text.TextFormat;
   import mmo.loader.common.datastructures.ResourceObject;
   import mmo.play.actthings.config.ActResConfigInfo;
   
   public class FIP_ResConfig
   {
      
      public static const PreResPath:String = "pet/";
      
      public static const PreClsView:String = "mmo.petfightnew.fightinfopanel.view.";
      
      private static const ResConfigInfo:ActResConfigInfo = new ActResConfigInfo(PreResPath + "fightinfopanel_",PreClsView);
      
      public static const SkillViewObj:ResourceObject = new ResourceObject(PreResPath + "fightinfopanel_main",PreClsView + "FIP_SkillView");
      
      public static const StatusViewObj:ResourceObject = new ResourceObject(PreResPath + "fightinfopanel_main",PreClsView + "FIP_StatusView");
      
      public static const EffectViewObj:ResourceObject = new ResourceObject(PreResPath + "fightinfopanel_main",PreClsView + "FIP_EffectView");
      
      public static const YinJiViewObj:ResourceObject = new ResourceObject(PreResPath + "fightinfopanel_main",PreClsView + "FIP_YinJiView");
      
      ResConfigInfo.registCalssResourceObject("FIP_MainPl","main");
      
      public function FIP_ResConfig()
      {
         super();
      }
      
      public static function getClassResObject(param1:*) : ResourceObject
      {
         return ResConfigInfo.getClassResObj(param1);
      }
      
      public static function loadResObj(param1:ResourceObject, param2:Function) : void
      {
         /*
          * Decompilation error
          * Code may be obfuscated
          * Tip: You can try enabling "Deobfuscate code" option in Settings
          * Error type: ClassCastException (com.jpexs.decompiler.graph.model.CommaExpressionItem cannot be cast to com.jpexs.decompiler.flash.abc.avm2.model.NewFunctionAVM2Item)
          */
         throw new flash.errors.IllegalOperationError("Not decompiled due to error");
      }
      
      public static function changeSkin(param1:ScrollPane) : void
      {
         param1.setStyle("trackUpSkin",ScrollTrack_skin);
         param1.setStyle("trackOverSkin",ScrollTrack_skin);
         param1.setStyle("trackDownSkin",ScrollTrack_skin);
         param1.setStyle("trackDisabledSkin",ScrollTrack_skin);
         param1.setStyle("upArrowUpSkin",ScrollArrowUp_downSkin);
         param1.setStyle("upArrowOverSkin",ScrollArrowUp_downSkin);
         param1.setStyle("upArrowDownSkin",ScrollArrowUp_downSkin);
         param1.setStyle("upArrowDisabledSkin",ScrollArrowUp_downSkin);
         param1.setStyle("downArrowUpSkin",ScrollArrowDown_downSkin);
         param1.setStyle("downArrowOverSkin",ScrollArrowDown_downSkin);
         param1.setStyle("downArrowDownSkin",ScrollArrowDown_downSkin);
         param1.setStyle("downArrowDisabledSkin",ScrollArrowDown_downSkin);
         param1.setStyle("thumbDownSkin",ScrollThumb_upSkin);
         param1.setStyle("thumbOverSkin",ScrollThumb_overSkin);
         param1.setStyle("thumbUpSkin",ScrollThumb_upSkin);
      }
      
      public static function createTextFormat(param1:int, param2:int, param3:String = "left") : TextFormat
      {
         var _loc4_:TextFormat = new TextFormat();
         _loc4_.font = "宋体";
         _loc4_.size = param1;
         _loc4_.letterSpacing = 1;
         _loc4_.leading = param2;
         _loc4_.align = param3;
         return _loc4_;
      }
      
      public static function getDomain() : ApplicationDomain
      {
         return ApplicationDomain.currentDomain;
      }
   }
}

