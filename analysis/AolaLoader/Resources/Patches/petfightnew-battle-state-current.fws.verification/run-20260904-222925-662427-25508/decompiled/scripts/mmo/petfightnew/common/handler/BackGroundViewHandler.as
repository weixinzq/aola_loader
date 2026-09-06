package mmo.petfightnew.common.handler
{
   import com.adobe.utils.ArrayUtil;
   import flash.display.Bitmap;
   import flash.display.DisplayObject;
   import flash.display.DisplayObjectContainer;
   import flash.display.MovieClip;
   import flash.display.Sprite;
   import flash.system.ApplicationDomain;
   import mmo.common.DisplayUtil;
   import mmo.common.utils.tips.TipsManager;
   import mmo.interfaces.IDispose;
   import mmo.interfaces.gq.GQPetType;
   import mmo.interfaces.pet.data.PetAssetsMap;
   import mmo.interfaces.pet.pm.services.IPMService;
   import mmo.loader.scheduler.ResDomain;
   import mmo.loader.scheduler.ResParams;
   import mmo.loader.scheduler.ResPriority;
   import mmo.loader.scheduler.ResScheduler;
   import mmo.petfightnew.common.FightController;
   import mmo.petfightnew.common.FightData;
   import mmo.petfightnew.common.handler.custombg.HunDunKongJianEffectHandle;
   import mmo.petfightnew.common.handler.custombg.SkillBackgroundBuff1453Handler;
   import mmo.petfightnew.common.manager.FightMovieManager;
   import mmo.petfightnew.common.manager.ServicePool;
   import mmo.petfightnew.common.util.BSUtil;
   import mmo.petfightnew.common.util.GetBackgroundUtil;
   import mmo.play.petfight.common.config.FightBSConfig;
   import mmo.play.scene.SceneManager;
   import mmo.util.component.artnumber.ArtNumberManager;
   
   public class BackGroundViewHandler implements IDispose
   {
      
      private const SKILL_BACK_GROUND_URL_PRE:String = "skillbackground/skillbackground_";
      
      private const SKILL_BACK_GROUND_ICON_URL_PRE:String = "petfightbsicon/icon_";
      
      private const BackGroundUpUrlPre:String = "gqpet/qiyuan/backgroundup/backgroundup_";
      
      private const BackGroundUpYanhuaZhiyaoUrlPre:String = "gqpet/yanhuazhiyao/backgroundup/backgroundup_";
      
      private const GQDiJieShiPreUrl:String = "gqpet/dijieshi/effect/dijieshieffect_";
      
      private const GQDiJieShiAppearCls:String = "mmo.gqpet.dijieshi.effect.DiJieShiAppearEffect_";
      
      private const GQDiJieShiPetUpKuangCls:String = "mmo.gqpet.dijieshi.effect.PetUpKuangEffect_";
      
      private const GQDiJieShiDisappearCls:String = "mmo.gqpet.dijieshi.effect.DiJieShiDisappearEffect_";
      
      private const GQXingHuanShiPreUrl:String = "gqpet/xinghuanshi/effect/xinghuanshieffect";
      
      private const GQXingHuanShiPetDownPreCls:String = "mmo.gqpet.xinghuanshi.effect.XingHuanShiPetDownEffect_";
      
      private const GQXingHuanShiPetUpCls:String = "mmo.gqpet.xinghuanshi.effect.XingHuanShiTurnCountEffect";
      
      private var _curBS:String = "";
      
      private var _sceneBack:DisplayObject = null;
      
      private var _skillBack:DisplayObject;
      
      private var _layerBackGround:DisplayObjectContainer = null;
      
      private var _backGroundIconContainer:DisplayObjectContainer = null;
      
      private var _layerPlatform:DisplayObjectContainer = null;
      
      private var _layerBackGroundUps:Array = [];
      
      private var _backGroundUpIds:Array = [-1,-1];
      
      private var _layerDijieshiPetDown:DisplayObjectContainer;
      
      private var _dijieshiPetUpRaceId:int;
      
      private var _pmSvr:IPMService = ServicePool.instance.getService(IPMService);
      
      private var _hunDunKongJianEffectHandle:HunDunKongJianEffectHandle;
      
      private var _xuniWeiduBuffHandler:SkillBackgroundBuff1453Handler;
      
      private var _layerXingHuanShiPetDown:DisplayObjectContainer;
      
      private var _xingHuanShiPetDownBss:Array = [];
      
      public function BackGroundViewHandler(param1:DisplayObjectContainer, param2:DisplayObjectContainer, param3:DisplayObjectContainer, param4:DisplayObjectContainer, param5:DisplayObjectContainer, param6:DisplayObjectContainer)
      {
         super();
         this._layerBackGround = param1;
         this._backGroundIconContainer = param2;
         this._layerPlatform = param3;
         this._layerBackGroundUps = [param4.getChildByName("mybackgroundup") as DisplayObjectContainer,param4.getChildByName("opponentsbackgroundup") as DisplayObjectContainer];
         this._layerDijieshiPetDown = param6.getChildByName("dijieshiPetDownLayer") as DisplayObjectContainer;
         this._layerDijieshiPetDown.mouseChildren = this._layerDijieshiPetDown.mouseEnabled = false;
         this._layerXingHuanShiPetDown = param6.getChildByName("xingHuanShiPetDownLayer") as DisplayObjectContainer;
         this._layerXingHuanShiPetDown.mouseChildren = this._layerXingHuanShiPetDown.mouseEnabled = false;
         this._hunDunKongJianEffectHandle = new HunDunKongJianEffectHandle(param6.getChildByName("hunDunPetDownLayer") as DisplayObjectContainer);
         this._xuniWeiduBuffHandler = new SkillBackgroundBuff1453Handler(param6.getChildByName("commonBuffPetDownLayer") as DisplayObjectContainer);
      }
      
      public function dispose() : void
      {
         DisplayUtil.stopAndRemove(this._sceneBack);
         this._sceneBack = null;
         DisplayUtil.stopAndRemove(this._skillBack);
         this._skillBack = null;
         DisplayUtil.stopAndRemove(this._layerBackGround);
         this._layerBackGround = null;
         DisplayUtil.stopAndRemove(this._backGroundIconContainer);
         this._backGroundIconContainer = null;
         DisplayUtil.stopAndRemove(this._layerBackGroundUps[0]);
         DisplayUtil.stopAndRemove(this._layerBackGroundUps[1]);
         this._layerBackGroundUps = [];
         this._hunDunKongJianEffectHandle.dispose();
         this._xuniWeiduBuffHandler.dispose();
      }
      
      public function setBS(param1:String) : void
      {
         this.setSkillBackGroundIcon(param1);
         if(param1 == null || param1.length == 0)
         {
            this.removeSkillBackGround();
         }
         else
         {
            this.changeSkillBackGround(param1);
         }
         this._hunDunKongJianEffectHandle.refresHunDunJueDouKongJianBg();
         this._xuniWeiduBuffHandler.refreshBg();
      }
      
      public function setBackGroundUp(param1:Array) : void
      {
         this.changeBackGroundUp(param1);
      }
      
      public function setPetUp(param1:Object) : void
      {
         var _loc2_:int = BSUtil.parseDiJieShiPetUp(param1.bs);
         this.changeDiJieShiPetUp(_loc2_);
         var _loc3_:Array = BSUtil.parseXingHuanShiPetDown(param1.bs);
         this.changeXingHuanShiPetDown(_loc3_);
         var _loc4_:int = BSUtil.parseXingHuanShiTurnCount(param1.bs);
         this.changeXingHuanShiPetDownTurnCount(_loc4_);
      }
      
      public function setSceneBackGround() : void
      {
         var _loc1_:String = SceneManager.getInstance().loadedSceneInfo.sceneName;
         this._sceneBack = GetBackgroundUtil.getBackground(_loc1_);
         this._layerBackGround.addChild(this._sceneBack);
         if(!(this._sceneBack is Bitmap))
         {
            this._sceneBack = DisplayUtil.replaceAsBitmap(this._sceneBack);
         }
      }
      
      private function setSkillBackGroundIcon(param1:String) : void
      {
         var bsKey:String;
         var bs:String = param1;
         if(!FightBSConfig.isCheckerBoard(bs) && !FightBSConfig.isNianFeiBg(bs) && !FightBSConfig.isLunhuishiyueBg(bs) && !FightBSConfig.isGQJueXingBg(bs) && !FightBSConfig.isOtherGQBg(bs))
         {
            this._layerPlatform.visible = true;
         }
         if(!FightBSConfig.isUsefulBS(bs) || FightBSConfig.getBSTips(bs) == "" || Boolean(FightBSConfig.isXingHuiKillBigBS(bs)))
         {
            TipsManager.getInstance().removeTips(this._backGroundIconContainer);
            DisplayUtil.clearChildren(this._backGroundIconContainer);
            return;
         }
         if(FightBSConfig.isSameBS(this._curBS,bs))
         {
            TipsManager.getInstance().replaceComplexTips(this._backGroundIconContainer,FightBSConfig.getBSName(bs),FightBSConfig.getBSTips(bs));
            return;
         }
         bsKey = FightBSConfig.getBSKey(bs);
         ResScheduler.getRes(ResParams.createTemp(this.SKILL_BACK_GROUND_ICON_URL_PRE + bsKey,function(param1:Sprite, param2:ApplicationDomain = null):void
         {
            DisplayUtil.clearChildren(_backGroundIconContainer);
            param1.x = -0.5 * param1.width;
            param1.y = -0.6 * param1.height;
            _backGroundIconContainer.addChild(param1);
         },"mmo.petfightnew.BSIcon_" + bsKey,ResPriority.NORMAL,function():void
         {
         }));
         TipsManager.getInstance().removeTips(this._backGroundIconContainer);
         TipsManager.getInstance().addComplexTips(this._backGroundIconContainer,FightBSConfig.getBSName(bs),FightBSConfig.getBSTips(bs));
      }
      
      private function changeSkillBackGround(param1:String) : void
      {
         var bsURL:String;
         var bsKey:String = null;
         var xclsName:String = null;
         var xskillBackClass:Class = null;
         var bs:String = param1;
         if(bs == "" || !FightBSConfig.isUsefulBS(bs) || Boolean(FightBSConfig.isSameBS(this._curBS,bs)))
         {
            return;
         }
         if(Boolean(FightBSConfig.isCheckerBoard(bs)) || Boolean(FightBSConfig.isNianFeiBg(bs)) || Boolean(FightBSConfig.isLunhuishiyueBg(bs)) || Boolean(FightBSConfig.isGQJueXingBg(bs)) || Boolean(FightBSConfig.isOtherGQBg(bs)))
         {
            this._layerPlatform.visible = false;
         }
         this._curBS = bs;
         bsKey = FightBSConfig.getBSKey(bs);
         bsURL = this.getSkillBackGroundUrl(bsKey);
         if(FightBSConfig.isXingHuiKillBigBS(bs))
         {
            DisplayUtil.stopAndRemove(this._sceneBack);
            xclsName = "mmo.petfightnew.XingHuiKillBigBg_" + bsKey;
            xskillBackClass = FightData.instance.applicationDomain.getDefinition(xclsName) as Class;
            this._skillBack = new xskillBackClass() as DisplayObject;
            this._layerBackGround.addChild(this._skillBack);
         }
         else
         {
            ResScheduler.getResource(bsURL,function(param1:MovieClip):void
            {
               var mc:MovieClip = param1;
               FightMovieManager.instance.addMovie(mc);
               mc.addFrameScript(mc.totalFrames - 1,function():void
               {
                  FightMovieManager.instance.removeMovie(mc);
                  DisplayUtil.stopAndRemove(mc);
                  DisplayUtil.stopAndRemove(_sceneBack);
                  DisplayUtil.stopAndRemove(_skillBack);
                  var _loc1_:String = "BackGroundMovie" + bsKey;
                  var _loc2_:Class = FightData.instance.applicationDomain.getDefinition(_loc1_) as Class;
                  _skillBack = new _loc2_() as DisplayObject;
                  _layerBackGround.addChild(_skillBack);
               });
               _layerBackGround.addChild(mc);
               mc.gotoAndPlay(1);
            },"BackGroundAppearMovie" + bsKey,null,null,ResPriority.NORMAL,false,FightData.instance.applicationDomain);
         }
      }
      
      private function changeBackGroundUp(param1:Array) : void
      {
         var _loc2_:int = 0;
         while(_loc2_ < param1.length)
         {
            if(param1[_loc2_] == -1)
            {
               this.removeBackGroundUpByIndex(_loc2_,null);
               this._backGroundUpIds[_loc2_] = -1;
            }
            else if(this._backGroundUpIds[_loc2_] != param1[_loc2_])
            {
               this.addLayerBackGroundUp(_loc2_,param1[_loc2_]);
            }
            this._backGroundUpIds[_loc2_] = param1[_loc2_];
            _loc2_++;
         }
      }
      
      private function changeDiJieShiPetUp(param1:int) : void
      {
         if(param1 > 0)
         {
            param1 = int(PetAssetsMap.getPetFlaId(this._pmSvr.getOperationPM(param1).getMaxCommonEvlution().raceId));
         }
         if(param1 != this._dijieshiPetUpRaceId)
         {
            if(this._dijieshiPetUpRaceId > 0)
            {
               this.removeDiJieShiPetUp();
               this._dijieshiPetUpRaceId = -1;
            }
            if(param1 > 0)
            {
               this._dijieshiPetUpRaceId = param1;
               this.addDiJieShiPetUp();
            }
         }
      }
      
      private function changeXingHuanShiPetDown(param1:Array) : void
      {
         var _loc2_:int = 0;
         if(ArrayUtil.arraysAreEqual(this._xingHuanShiPetDownBss,param1))
         {
            return;
         }
         DisplayUtil.stopAndRemoveChild(this._layerXingHuanShiPetDown);
         if(param1.length > 0)
         {
            this._xingHuanShiPetDownBss = param1;
            _loc2_ = 0;
            while(_loc2_ < param1.length)
            {
               this.addXingHuanShiPetDown(param1[_loc2_]);
               _loc2_++;
            }
         }
      }
      
      private function changeXingHuanShiPetDownTurnCount(param1:int) : void
      {
         var key:String = null;
         var layer:Sprite = null;
         var xhsTurn:int = param1;
         var setNumber:Function = function(param1:MovieClip):void
         {
            if(Boolean(param1) && Boolean(param1.parent))
            {
               ArtNumberManager.setNumber([param1.mc0,param1.mc1],xhsTurn);
            }
         };
         key = "XingHuanShiPetDownTurnCount";
         layer = FightController.instance.fightPanel.layerPetUp;
         var hasView:Boolean = layer.getChildByName(key) != null;
         if(xhsTurn <= 0)
         {
            if(hasView)
            {
               layer.removeChild(layer.getChildByName(key));
            }
            return;
         }
         if(hasView)
         {
            setNumber(layer.getChildByName(key) as MovieClip);
         }
         else
         {
            ResScheduler.getRes(ResParams.createTempByDomain(this.GQXingHuanShiPreUrl,function(param1:MovieClip, param2:ApplicationDomain):void
            {
               param1.name = key;
               param1.mouseEnabled = param1.mouseChildren = false;
               param1.x = 464;
               param1.y = 9;
               layer.addChild(param1);
               setNumber(param1);
            },ResDomain.decorate(FightData.instance.applicationDomain),this.GQXingHuanShiPetUpCls,ResPriority.LOW));
         }
      }
      
      private function addLayerBackGroundUp(param1:int, param2:int) : void
      {
         var index:int = param1;
         var id:int = param2;
         try
         {
            ResScheduler.getResource(this.BackGroundUpUrlPre + id + "_" + index,function(param1:MovieClip):void
            {
               var mc:MovieClip = param1;
               DisplayUtil.stopAndRemoveChild(_layerBackGroundUps[index]);
               FightMovieManager.instance.addMovie(mc);
               mc.addFrameScript(mc.totalFrames - 1,function():void
               {
                  FightMovieManager.instance.removeMovie(mc);
                  DisplayUtil.stopAndRemove(mc);
                  var _loc1_:String = "BackGroundUpMovie_" + id + "_" + index;
                  var _loc2_:Class = FightData.instance.applicationDomain.getDefinition(_loc1_) as Class;
                  var _loc3_:DisplayObject = new _loc2_() as DisplayObject;
                  _layerBackGroundUps[index].addChild(_loc3_);
               });
               _layerBackGroundUps[index].addChild(mc);
               mc.gotoAndPlay(1);
            },"BackGroundUpAppearMovie_" + id + "_" + index,function():void
            {
            },null,ResPriority.NORMAL,false,FightData.instance.applicationDomain);
         }
         catch(e:*)
         {
         }
      }
      
      private function addDiJieShiPetUp() : void
      {
         try
         {
            ResScheduler.getResource(this.GQDiJieShiPreUrl + this._dijieshiPetUpRaceId,function(param1:MovieClip):void
            {
               var mc:MovieClip = param1;
               DisplayUtil.stopAndRemoveChild(_layerDijieshiPetDown);
               FightMovieManager.instance.addMovie(mc);
               mc.addFrameScript(mc.totalFrames - 1,function():void
               {
                  FightMovieManager.instance.removeMovie(mc);
                  DisplayUtil.stopAndRemove(mc);
                  var _loc1_:String = GQDiJieShiPetUpKuangCls + _dijieshiPetUpRaceId;
                  var _loc2_:Class = FightData.instance.applicationDomain.getDefinition(_loc1_) as Class;
                  var _loc3_:DisplayObject = new _loc2_() as DisplayObject;
                  _layerDijieshiPetDown.addChild(_loc3_);
               });
               _layerDijieshiPetDown.addChild(mc);
            },this.GQDiJieShiAppearCls + this._dijieshiPetUpRaceId,function():void
            {
            },null,ResPriority.NORMAL,false,FightData.instance.applicationDomain);
         }
         catch(e:*)
         {
         }
      }
      
      private function addXingHuanShiPetDown(param1:int) : void
      {
         var viewId:int = 0;
         var raceId:int = param1;
         try
         {
            if(raceId > 0)
            {
               raceId = int(PetAssetsMap.getPetFlaId(this._pmSvr.getOperationPM(raceId).getMaxCommonEvlution().raceId));
               viewId = 5659;
               if(GQPetType.getXingHuanShiObject(raceId))
               {
                  viewId = int(GQPetType.getXingHuanShiObject(raceId).viewId);
               }
               ResScheduler.getResource(this.GQXingHuanShiPreUrl + "_" + viewId,function(param1:MovieClip):void
               {
                  _layerXingHuanShiPetDown.addChild(param1);
               },this.GQXingHuanShiPetDownPreCls + viewId,function():void
               {
               },null,ResPriority.NORMAL,false,FightData.instance.applicationDomain);
            }
         }
         catch(e:*)
         {
         }
      }
      
      private function removeSkillBackGround() : void
      {
         var bsKey:String = null;
         var pathName:String = null;
         var className:String = null;
         if(!FightBSConfig.isCheckerBoard(this._curBS) && !FightBSConfig.isNianFeiBg(this._curBS) && !FightBSConfig.isLunhuishiyueBg(this._curBS) && !FightBSConfig.isGQJueXingBg(this._curBS) && !FightBSConfig.isOtherGQBg(this._curBS))
         {
            this._layerPlatform.visible = true;
         }
         if(FightBSConfig.isXingHuiKillBigBS(this._curBS))
         {
            DisplayUtil.stopAndRemove(this._skillBack);
         }
         else if(this._curBS != null && this._curBS != "")
         {
            bsKey = FightBSConfig.getBSKey(this._curBS);
            pathName = "skillbackground/skillbackground_" + bsKey;
            className = "BackGroundDisappearMovie" + bsKey;
            ResScheduler.getResource(pathName,function(param1:MovieClip):void
            {
               var mc:MovieClip = param1;
               _curBS = "";
               DisplayUtil.stopAndRemove(_skillBack);
               FightMovieManager.instance.addMovie(mc);
               mc.addFrameScript(mc.totalFrames - 1,function():void
               {
                  FightMovieManager.instance.removeMovie(mc);
                  DisplayUtil.stopAndRemove(mc);
               });
               if(_layerBackGround != null && _layerBackGround.parent != null)
               {
                  _layerBackGround.addChild(mc);
                  mc.gotoAndPlay(1);
               }
            },className,null,null,ResPriority.NORMAL,false,FightData.instance.applicationDomain);
         }
         if(this._layerBackGround != null && this._layerBackGround.parent != null && this._sceneBack != null)
         {
            this._layerBackGround.addChildAt(this._sceneBack,0);
         }
      }
      
      private function removeBackGroundUpByIndex(param1:int, param2:Function) : void
      {
         var index:int = param1;
         var callback:Function = param2;
         if(this._backGroundUpIds[index] != -1)
         {
            try
            {
               ResScheduler.getResource(this.BackGroundUpUrlPre + this._backGroundUpIds[index] + "_" + index,function(param1:MovieClip):void
               {
                  var mc:MovieClip = param1;
                  FightMovieManager.instance.addMovie(mc);
                  mc.addFrameScript(mc.totalFrames - 1,function():void
                  {
                     FightMovieManager.instance.removeMovie(mc);
                     DisplayUtil.stopAndRemove(mc);
                     DisplayUtil.stopAndRemoveChild(_layerBackGroundUps[index]);
                  });
                  _layerBackGroundUps[index].addChild(mc);
                  mc.gotoAndPlay(1);
               },"BackGroundUpDisappearMovie_" + this._backGroundUpIds[index] + "_" + index,function():void
               {
               },null,ResPriority.NORMAL,false,FightData.instance.applicationDomain);
            }
            catch(e:*)
            {
            }
         }
      }
      
      private function removeDiJieShiPetUp() : void
      {
         if(this._dijieshiPetUpRaceId > 0)
         {
            try
            {
               ResScheduler.getResource(this.GQDiJieShiPreUrl + this._dijieshiPetUpRaceId,function(param1:MovieClip):void
               {
                  var mc:MovieClip = param1;
                  DisplayUtil.stopAndRemoveChild(_layerDijieshiPetDown);
                  FightMovieManager.instance.addMovie(mc);
                  mc.addFrameScript(mc.totalFrames - 1,function():void
                  {
                     FightMovieManager.instance.removeMovie(mc);
                     DisplayUtil.stopAndRemove(mc);
                  });
                  _layerDijieshiPetDown.addChild(mc);
                  mc.gotoAndPlay(1);
               },this.GQDiJieShiDisappearCls + this._dijieshiPetUpRaceId,function():void
               {
               },null,ResPriority.NORMAL,false,FightData.instance.applicationDomain);
            }
            catch(e:*)
            {
            }
         }
      }
      
      private function getSkillBackGroundUrl(param1:String) : String
      {
         return this.SKILL_BACK_GROUND_URL_PRE + param1;
      }
      
      public function get curBS() : String
      {
         return this._curBS;
      }
   }
}

