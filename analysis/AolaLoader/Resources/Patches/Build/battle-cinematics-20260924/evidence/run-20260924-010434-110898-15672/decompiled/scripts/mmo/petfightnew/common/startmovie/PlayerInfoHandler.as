package mmo.petfightnew.common.startmovie
{
   import flash.display.DisplayObjectContainer;
   import flash.display.MovieClip;
   import flash.display.Sprite;
   import flash.events.Event;
   import flash.text.TextField;
   import mmo.common.eventdispatcher.CommonEventDispatcher;
   import mmo.framework.comm.SocketClient;
   import mmo.interfaces.pet.data.PetBriefInfo;
   import mmo.interfaces.pet.data.PlayerBattleInfo;
   import mmo.petfightnew.common.FightData;
   import mmo.petfightnew.common.util.PreLoadAssetsUtil;
   import mmo.play.activity.helper.Panel_Helper;
   import mmo.play.actthings.helper.ActComHelper;
   import mmo.util.component.artnumber.ArtNumberManager;
   
   public class PlayerInfoHandler
   {
      
      private static const CMD_GET_NAME_BY_ID:String = "getNameById";
      
      public static const LOAD_DONE:String = "LOAD_DONE";
      
      private var _isLoadDefaultHaed:Boolean = false;
      
      private var raceIdToName:Object = {
         10089:{"name":"锐角羊龙"},
         10186:{"name":"维克"},
         10299:{"name":"哈德"},
         70105:{"name":"神武月"},
         70103:{"name":"赤月"},
         70109:{"name":"炎风"},
         30317:{"name":"天使莱特"},
         10323:{"name":"拉贝尔"},
         40105:{"name":"神武月"},
         40111:{"name":"战无炎"},
         70111:{"name":"战无炎"},
         10091:{"name":"木面仔"},
         10653:{"name":"飞天独角兽"},
         10675:{"name":"白天鹅"},
         20682:{"name":"黑夜童心"},
         30731:{"name":"修罗"},
         50731:{"name":"修罗"},
         10849:{"name":"神射手糖糖"},
         20846:{"name":"小白吐"},
         10894:{"name":"亚伦"},
         10896:{"name":"贝琪"},
         20895:{"name":"利克亚伦"},
         20897:{"name":"百变贝琪"},
         10915:{"name":"泽时"},
         10914:{"name":"泽分"},
         10731:{"name":"修罗"},
         10967:{"name":"巨岩"},
         10980:{"name":"路比比"},
         40860:{"name":"关羽"},
         40955:{"name":"张飞"},
         21081:{"name":"奇奇"},
         51082:{"name":"奥奇"},
         11122:{"name":"狼王"},
         161082:{"name":"奥奇"},
         11182:{"name":"黑皮"},
         11183:{"name":"捣蛋黑皮"},
         11184:{"name":"飞灵"},
         11227:{"name":"茜点"},
         10563:{"name":"蓝宝星"},
         21259:{"name":"友人契约书"},
         31282:{"name":"施瓦辛格"},
         31259:{"name":"友人契约书"},
         31267:{"name":"多古拉伯爵"},
         190147:{"name":"芭芭拉"},
         190653:{"name":"小南姐姐"},
         190901:{"name":"贝鲁特"},
         190768:{"name":"泰勒"},
         190186:{"name":"维克"},
         190323:{"name":"拉贝尔"},
         21320:{"name":"伊泽"},
         21322:{"name":"迦娜"},
         21286:{"name":"波波嘟"},
         61122:{"name":"狼王迪洛斯"},
         61135:{"name":"赤翼魔龙王"},
         61142:{"name":"幻灵"},
         1379:{"name":"斯巴达"},
         1409:{"name":"铁迪"},
         81240:{"name":"乐天"},
         81227:{"name":"茜点"},
         81257:{"name":"雏菊仙子"},
         81265:{"name":"多米力"},
         81312:{"name":"海琪琪"},
         231473:{"name":"圣灵星诺"},
         51538:{"name":"炼狱战狮"},
         51539:{"name":"炼狱狮王"},
         51541:{"name":"魔戒邪灵"},
         21556:{"name":"斑比"},
         11577:{"name":"王者蒙奇"},
         1615:{"name":"太白"},
         10328:{"name":"SR战士"},
         11645:{"name":"圣盾"},
         61754:{"name":"炎王•火龙态"},
         61777:{"name":"帝卡•影龙态"},
         61825:{"name":"明王•巨龙态"},
         61873:{"name":"冰罗皇冰龙态"},
         81896:{"name":"圣•天伊"},
         80731:{"name":"修罗"},
         120105:{"name":"神武月"},
         181122:{"name":"狼王迪洛斯"},
         80728:{"name":"凯撒"},
         120111:{"name":"战无炎"},
         101124:{"name":"夜王狄米特"},
         31854:{"name":"诺伊特"},
         21726:{"name":"利威尔"},
         20003:{"name":"大师兔"},
         11200:{"name":"魔剑守卫"},
         11403:{"name":"暗影兽"},
         70006:{"name":"爆焰吉拉"},
         20009:{"name":"露西亚"},
         11120:{"name":"冰刃侠"},
         41854:{"name":"诺伊特"},
         31726:{"name":"利威尔"},
         32027:{"name":"裂空菲洛"}
      };
      
      private const nameArr:Array = ["守护"];
      
      public function PlayerInfoHandler()
      {
         super();
      }
      
      public function handlePlayerInfo(param1:PlayerBattleInfo, param2:Sprite, param3:DisplayObjectContainer) : void
      {
         var _loc6_:DisplayObjectContainer = null;
         var _loc7_:DisplayObjectContainer = null;
         var _loc4_:MovieClip = param2.getChildByName("mcIcon") as MovieClip;
         if(param1.PMMasterId > 0)
         {
            _loc4_.gotoAndStop(this._isLoadDefaultHaed ? 3 : 2);
         }
         else
         {
            _loc4_.gotoAndStop(1);
         }
         var _loc5_:MovieClip = param2.getChildByName("mcBall") as MovieClip;
         _loc5_.gotoAndStop(param1.PMCanBattle);
         this.setBlueIcon(param1,param2);
         this.setPlayerName(param1,param2);
         this.setProgress(param1,param2);
         this.setBattlePower(param1,param2);
         this.setSummonerInfo(param1,param2);
         if(param1.PMMasterId > 0 && !this._isLoadDefaultHaed)
         {
            _loc6_ = _loc4_.getChildByName("mcplayerhead") as DisplayObjectContainer;
            if(_loc6_ == null || param3 == null)
            {
               return;
            }
            _loc7_ = _loc6_.getChildByName("mc") as DisplayObjectContainer;
            if(_loc7_ != null)
            {
               _loc7_.addChild(param3);
            }
         }
      }
      
      private function setSummonerInfo(param1:PlayerBattleInfo, param2:Sprite) : void
      {
      }
      
      private function setBattlePower(param1:PlayerBattleInfo, param2:Sprite) : void
      {
         var _loc4_:MovieClip = null;
         var _loc5_:Array = null;
         var _loc6_:MovieClip = null;
         var _loc7_:MovieClip = null;
         var _loc3_:MovieClip = param2.getChildByName("mcBattlePower") as MovieClip;
         if(param1.packageBattlePower > 0)
         {
            _loc3_.gotoAndStop(1);
            _loc4_ = _loc3_.getChildByName("mcTotalBattlePower") as MovieClip;
            _loc5_ = Panel_Helper.getSubClips(_loc4_,6);
            ArtNumberManager.setNumber(_loc5_,param1.totalBattlePower);
            Panel_Helper.setTextValue(_loc3_,"txtPackageBattlePower",param1.packageBattlePower.toString());
            Panel_Helper.setTextValue(_loc3_,"txtPetCorpsBattlePower",param1.petCorpsBattlePower.toString());
            _loc6_ = _loc3_.getChildByName("mcPackageBattlePower") as MovieClip;
            if(_loc6_)
            {
               _loc5_ = Panel_Helper.getSubClips(_loc6_,6);
               ArtNumberManager.setNumber(_loc5_,param1.packageBattlePower);
            }
            ActComHelper.setVisible(_loc3_,"mcPetCorpsIcon",param1.petCorpsBattlePower > 0);
            _loc7_ = _loc3_.getChildByName("mcPetCorpsBattlePower") as MovieClip;
            if(_loc7_)
            {
               if(param1.petCorpsBattlePower > 0)
               {
                  _loc7_.visible = true;
                  _loc5_ = Panel_Helper.getSubClips(_loc7_,6);
                  ArtNumberManager.setNumber(_loc5_,param1.petCorpsBattlePower);
               }
               else
               {
                  _loc7_.visible = false;
               }
            }
         }
         else
         {
            _loc3_.gotoAndStop(2);
         }
      }
      
      private function setBlueIcon(param1:PlayerBattleInfo, param2:Sprite) : void
      {
         var _loc3_:Sprite = param2.getChildByName("spBlue") as Sprite;
         _loc3_.visible = param1.isVip;
      }
      
      private function setPlayerName(param1:PlayerBattleInfo, param2:Sprite) : void
      {
         var _loc4_:int = 0;
         var _loc5_:String = null;
         var _loc6_:int = 0;
         var _loc3_:TextField = param2.getChildByName("txtName") as TextField;
         _loc3_.mouseEnabled = false;
         if(FightData.instance.challengeNpcId > 0)
         {
            _loc3_.text = FightData.instance.npcName;
         }
         else if(param1.PMMasterId < 0)
         {
            if(FightData.instance.isMySide(param1.locaId))
            {
               _loc4_ = int(PetBriefInfo(param1.myPets[0]).raceId);
               if(this.raceIdToName[_loc4_] != null)
               {
                  _loc3_.text = this.raceIdToName[_loc4_].name;
               }
               else
               {
                  _loc5_ = FightData.instance.getNextAiName();
                  if(_loc5_ == null)
                  {
                     _loc6_ = Math.floor(Math.random() * this.nameArr.length);
                     _loc3_.text = this.nameArr[_loc6_];
                  }
                  else
                  {
                     _loc3_.text = _loc5_;
                  }
               }
            }
            else
            {
               _loc3_.text = this.nameArr[Math.floor(Math.random() * this.nameArr.length)];
            }
         }
         else
         {
            _loc3_.text = param1.nickName;
         }
      }
      
      private function getNameByIds(param1:Array) : void
      {
         var _loc2_:* = "";
         var _loc3_:int = 0;
         while(_loc3_ < param1.length)
         {
            if(_loc3_ > 0)
            {
               _loc2_ += ",";
            }
            _loc2_ += param1[_loc3_];
            _loc3_++;
         }
         SocketClient.instance.sendXtMessage("UserExtension",CMD_GET_NAME_BY_ID,{"ids":_loc2_});
      }
      
      private function setProgress(param1:PlayerBattleInfo, param2:Sprite) : void
      {
         var mcProgress:MovieClip = null;
         var onFrame:Function = null;
         var onRemove:Function = null;
         var playerInfo:PlayerBattleInfo = param1;
         var spPlayerInfo:Sprite = param2;
         mcProgress = spPlayerInfo.getChildByName("mcProgress") as MovieClip;
         onFrame = function(param1:Event):void
         {
            if(PreLoadAssetsUtil.instance.isLoading)
            {
               mcProgress.gotoAndStop(Math.floor(mcProgress.totalFrames * PreLoadAssetsUtil.instance.progress) + 1);
            }
            else if(PreLoadAssetsUtil.instance.progress >= 1)
            {
               mcProgress.gotoAndStop(Math.floor(mcProgress.totalFrames * PreLoadAssetsUtil.instance.progress) + 1);
               spPlayerInfo.removeEventListener(Event.ENTER_FRAME,onFrame);
               spPlayerInfo.removeEventListener(Event.REMOVED_FROM_STAGE,onRemove);
               CommonEventDispatcher.instance.dispatchEvent(new Event(LOAD_DONE));
            }
         };
         onRemove = function onRemove(param1:Event):void
         {
            spPlayerInfo.removeEventListener(Event.ENTER_FRAME,onFrame);
            spPlayerInfo.removeEventListener(Event.REMOVED_FROM_STAGE,onRemove);
         };
         spPlayerInfo.addEventListener(Event.ENTER_FRAME,onFrame);
         spPlayerInfo.addEventListener(Event.REMOVED_FROM_STAGE,onRemove);
      }
   }
}

